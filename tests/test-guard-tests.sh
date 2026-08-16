#!/usr/bin/env bash
# Tests for claude/hooks/test-guard.sh.
#
# Like monitor-guard this hook must never block, so exit status is always 0 and the payload travels
# in stdout JSON. What is asserted here is the discrimination: a report on edits that carry marks of
# weakening, silence on edits that do not and on files that are not tests. A hook that reports on
# everything is noise, and noise gets ignored, which is indistinguishable from having no hook.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="${REPO_ROOT}/claude/hooks/test-guard.sh"

declare -i RUN=0 FAILED=0

# expect_report <yes|no> <label> <file_path> <old_string> <new_string>
expect_report() {
	local want="$1" label="$2" path="$3" old="$4" new="$5"
	RUN+=1
	local payload out status got

	payload="$(P="${path}" O="${old}" N="${new}" python3 -c '
import json, os
print(json.dumps({"tool_name": "Edit", "tool_input": {
    "file_path": os.environ["P"],
    "old_string": os.environ["O"],
    "new_string": os.environ["N"],
}}))')"

	out="$(printf '%s' "${payload}" | bash "${GUARD}" 2>/dev/null)"
	status=$?

	if ((status != 0)); then
		FAILED+=1
		printf 'FAIL: %s — hook exited %d; it must never block\n' "${label}" "${status}"
		return
	fi

	# Both channels are asserted together: systemMessage reaches the human and additionalContext the
	# model, and a hook that populated only one would report to half its audience while looking fine.
	got="$(printf '%s' "${out}" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    h = d.get("hookSpecificOutput", {})
    ok = (h.get("hookEventName") == "PostToolUse"
          and h.get("additionalContext")
          and d.get("systemMessage"))
    print("yes" if ok else "no")
except Exception:
    print("no")
' 2>/dev/null)"

	if [[ ${got} == "${want}" ]]; then
		printf 'PASS: report=%s — %s\n' "${want}" "${label}"
	else
		FAILED+=1
		printf 'FAIL: wanted report=%s got %s — %s\n' "${want}" "${got}" "${label}"
	fi
}

# The three signals the hook claims to detect.
expect_report yes "assertion removed from a vitest spec" \
	"src/parser.test.ts" \
	'expect(parse("a")).toBe(1); expect(parse("b")).toBe(2);' \
	'expect(parse("a")).toBe(1);'

expect_report yes "skip marker added" \
	"src/parser.test.ts" \
	'it("parses", () => { expect(parse("a")).toBe(1); });' \
	'it.skip("parses", () => { expect(parse("a")).toBe(1); });'

expect_report yes "whole test case deleted from a python suite" \
	"tests/test_roadmap.py" \
	'def test_valid():
    assert ok
def test_invalid():
    assert not bad' \
	'def test_valid():
    assert ok'

# `.only` does not weaken the edited test — it silences every other test in the file, which is the
# same loss of coverage arriving by a different route.
expect_report yes "only marker narrows the run" \
	"src/parser.test.ts" \
	'describe("parse", () => { it("a", () => { expect(1).toBe(1); }); });' \
	'describe.only("parse", () => { it("a", () => { expect(1).toBe(1); }); });'

# Silence cases. Strengthening and pure renames must not report, or the signal drowns.
expect_report no "assertion added" \
	"src/parser.test.ts" \
	'expect(parse("a")).toBe(1);' \
	'expect(parse("a")).toBe(1); expect(parse("b")).toBe(2);'

expect_report no "rename preserves every count" \
	"src/parser.test.ts" \
	'it("parses input", () => { expect(parse("a")).toBe(1); });' \
	'it("parses a single token", () => { expect(parse("a")).toBe(1); });'

# Path discrimination: the same weakening edit outside a test file is not this hook's business.
expect_report no "production file with a falling assert count" \
	"src/parser.ts" \
	'assert(x); assert(y);' \
	'assert(x);'

# This repo's own bash suites are test files by directory, and their assertions are bare words
# rather than calls — the path and token rules both have to reach them.
expect_report yes "bash suite loses a run_test case" \
	"tests/install-tests.sh" \
	'run_test "links runcoms" test_links
run_test "skips existing" test_skips' \
	'run_test "links runcoms" test_links'

# A malformed payload must fall through silently rather than fail loudly on the hook's own defect.
RUN+=1
if printf '%s' 'not json at all' | bash "${GUARD}" >/dev/null 2>&1; then
	printf 'PASS: malformed payload exits 0\n'
else
	FAILED+=1
	printf 'FAIL: malformed payload did not exit 0\n'
fi

printf '\n%d run, %d failed\n' "${RUN}" "${FAILED}"
((FAILED == 0))
