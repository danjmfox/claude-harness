#!/usr/bin/env bash
# test-guard — PostToolUse(Edit) hook. Reports edits to test files that carry the textual marks of
# weakening (see ~/.claude/CLAUDE.md — Test Modification Prohibition). Never blocks.
#
# PostToolUse cannot block, and that is why it is the right event: whether an edit weakens a test is
# undecidable from a diff, so a gate here would either wave real weakening through or stop
# legitimate refactors. Reporting rather than deciding keeps both failure modes off the table.
#
# The report goes out on both channels on purpose. systemMessage is a universal hook output field
# and reaches the human; additionalContext reaches the model but is not documented for this event,
# so relying on it alone would risk a hook that silently reports to nobody.
set -uo pipefail

INPUT="$(cat)"

# Absence is an expected branch: a malformed or non-Edit payload leaves nothing to compare, and the
# hook must never fail loudly on its own defect.
PAYLOAD="${INPUT}" python3 <<'PY' 2>/dev/null || true
import json
import os
import re
import sys

try:
    payload = json.loads(os.environ["PAYLOAD"])
except Exception:
    sys.exit(0)

edit = payload.get("tool_input") or {}
path = edit.get("file_path") or ""
old = edit.get("old_string") or ""
new = edit.get("new_string") or ""
if not path or not (old or new):
    sys.exit(0)

TEST_PATH = re.compile(
    r"(^|/)(tests?|spec|__tests__)/"
    r"|(_test|_spec|-test|-tests|\.test|\.spec)\.[A-Za-z0-9]+$"
    r"|(^|/)test_[^/]*\.py$"
    r"|Tests?\.(java|cs|kt)$"
)
if not TEST_PATH.search(path):
    sys.exit(0)

# Counted as separate token classes rather than one alternation so the report can name what moved.
ASSERTIONS = [r"\bexpect(?:_quiet)?\b", r"\bassert\w*\b"]
CASES = [r"\bit\s*\(", r"\btest\s*\(", r"\bdef test_", r"\bfunc Test", r"\brun_test\b"]
SKIPS = [
    r"\.skip\b",
    r"\.only\b",
    r"\bxit\s*\(",
    r"\bxdescribe\s*\(",
    r"\bt\.Skip\b",
    r"@pytest\.mark\.skip",
    r"@unittest\.skip",
    r"@Disabled\b",
    r"\bxfail\b",
]


def count(patterns, text):
    return sum(len(re.findall(p, text)) for p in patterns)


notes = []
for label, patterns, direction in (
    ("assertions", ASSERTIONS, "fell"),
    ("test-case declarations", CASES, "fell"),
    ("skip/only markers", SKIPS, "rose"),
):
    before, after = count(patterns, old), count(patterns, new)
    if (direction == "fell" and after < before) or (direction == "rose" and after > before):
        notes.append(f"{label} {direction} from {before} to {after}")

if not notes:
    sys.exit(0)

# Declarative phrasing is load-bearing, not stylistic: additionalContext written as instructions can
# be filtered as prompt injection, which would drop the report without a trace.
report = (
    f"Edit to {path} moved test-strength signals: "
    + "; ".join(notes)
    + ". The Test Modification Prohibition holds that a failing test is never weakened, removed or "
    "relaxed to make it pass; where the implementation genuinely cannot satisfy it, the route is to "
    "flag the blocker with three documented attempts and surface it for review. "
    "These counts are textual and settle nothing on their own — a rename, an extraction or a "
    "parametrisation moves them too. What they cannot see is a loosened tolerance, a weakened "
    "matcher or a narrowed input set, so an unchanged count is not evidence that strength survived."
)

print(
    json.dumps(
        {
            "systemMessage": report,
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": report,
            },
        }
    )
)
PY
exit 0
