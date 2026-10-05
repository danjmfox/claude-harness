#!/usr/bin/env bash
# red-gate — PreToolUse(Edit|Write|MultiEdit), PostToolUse/PostToolUseFailure(Bash) and Stop hook.
# Blocks edits to gated paths unless the last recorded test run failed, and blocks Stop while edits
# have no passing run after them. Opt-in per project through .claude/red-gate.json.
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

def load_state():
    try:
        with open(state_file) as handle:
            return json.load(handle)
    except Exception:
        return {}


def save_state(**changes):
    state = {**load_state(), **changes}
    with open(state_file, "w") as handle:
        json.dump(state, handle)


def log_bypass(reason, target):
    entry = {
        "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "path": target,
        "reason": reason,
    }
    with open(os.path.join(project, ".claude", "red-gate-bypass.jsonl"), "a") as handle:
        handle.write(json.dumps(entry) + "\n")


event = payload.get("hook_event_name")
if event == "Stop":
    if load_state().get("dirty"):
        if payload.get("stop_hook_active"):
            log_bypass("unresolved-at-stop", "")
            sys.exit(0)
        if os.environ.get("RED_GATE_BYPASS"):
            log_bypass(os.environ["RED_GATE_BYPASS"], "")
            sys.exit(0)
        print(
            "WHAT: finishing blocked, gated edits have no passing test run after them.\n"
            "WHY: the last edit is unverified until the suite has run green.\n"
            "NEXT: run the test command and fix any failures, then finish.",
            file=sys.stderr,
        )
        sys.exit(2)
    sys.exit(0)

if event in ("PostToolUse", "PostToolUseFailure") and payload.get("tool_name") == "Bash":
    if re.search(config.get("test_command", "npm test|vitest"), tool_input.get("command") or ""):
        if event == "PostToolUseFailure":
            save_state(phase="RED")
        else:
            save_state(phase="GREEN", dirty=False)
    sys.exit(0)

phase = load_state().get("phase")

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
    save_state(dirty=True)
    sys.exit(0)

bypass = os.environ.get("RED_GATE_BYPASS")
if bypass:
    log_bypass(bypass, relative)
    save_state(dirty=True)
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
