#!/usr/bin/env bash
# red-gate — PreToolUse(Edit|Write|MultiEdit) and PostToolUse/PostToolUseFailure(Bash) hook.
# Blocks edits to gated paths unless the last recorded test run failed. Opt-in per project through
# .claude/red-gate.json.
set -uo pipefail

INPUT="$(cat)"

PAYLOAD="${INPUT}" python3 <<'PY'
import datetime
import json
import os
import re
import sys

try:
    payload = json.loads(os.environ["PAYLOAD"])
except Exception:
    sys.exit(0)

tool_input = payload.get("tool_input") or {}
path = tool_input.get("file_path") or ""
project = payload.get("cwd") or ""

try:
    with open(os.path.join(project, ".claude", "red-gate.json")) as handle:
        config = json.load(handle)
except Exception:
    sys.exit(0)

state_file = os.path.join(project, ".claude", "red-gate-state.json")

event = payload.get("hook_event_name")
if event in ("PostToolUse", "PostToolUseFailure") and payload.get("tool_name") == "Bash":
    if re.search(config.get("test_command", "npm test|vitest"), tool_input.get("command") or ""):
        with open(state_file, "w") as handle:
            json.dump({"phase": "RED" if event == "PostToolUseFailure" else "GREEN"}, handle)
    sys.exit(0)

try:
    with open(state_file) as handle:
        phase = json.load(handle).get("phase")
except Exception:
    phase = None

relative = os.path.relpath(path, project) if path else ""

if relative in (".claude/red-gate-state.json", ".claude/red-gate-bypass.jsonl"):
    print(
        f"WHAT: write to {relative} blocked.\n"
        "WHY: only the hook writes gate evidence; a model-written state file is a claim, not evidence.\n"
        "NEXT: run the test command so the hook records the result itself.",
        file=sys.stderr,
    )
    sys.exit(2)
if not any(relative.startswith(prefix) for prefix in config.get("gated", ["src/"])):
    sys.exit(0)

if phase == "RED":
    sys.exit(0)

bypass = os.environ.get("RED_GATE_BYPASS")
if bypass:
    entry = {
        "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "path": relative,
        "reason": bypass,
    }
    with open(os.path.join(project, ".claude", "red-gate-bypass.jsonl"), "a") as handle:
        handle.write(json.dumps(entry) + "\n")
    sys.exit(0)

print(
    f"WHAT: edit to {path} blocked, no failing test is recorded.\n"
    "WHY: a gated edit needs a RED test first.\n"
    "NEXT: run the test command and watch it fail, then retry.",
    file=sys.stderr,
)
sys.exit(2)
PY
exit $?
