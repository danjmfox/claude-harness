#!/usr/bin/env bash
# agent-guard — PostToolUse(Agent) hook. States that a background subagent is now running and
# unobserved (see ~/.claude/skills/watch/SKILL.md). Never blocks.
#
# PostToolUse rather than PreToolUse: before the dispatch there is no agent and nothing concrete to
# say, whereas after it the call has returned and the fact is checkable. No hook can verify a future
# action, so no hook can require that a watch is then armed — advisory is the ceiling here.
#
# Absence of run_in_background means background: the Agent tool dispatches asynchronously unless
# run_in_background is explicitly false, so gating on a true value would miss the common case.
set -uo pipefail

INPUT="$(cat)"

PAYLOAD="${INPUT}" python3 <<'PY' 2>/dev/null || true
import json
import os
import sys

try:
    payload = json.loads(os.environ["PAYLOAD"])
except Exception:
    sys.exit(0)

dispatch = payload.get("tool_input") or {}
if not dispatch:
    sys.exit(0)

background = dispatch.get("run_in_background", True)
if background is False or str(background).strip().lower() in {"false", "0", "no"}:
    sys.exit(0)

agent = dispatch.get("subagent_type") or "agent"
what = dispatch.get("description") or "unnamed task"

# Declarative phrasing is load-bearing, not stylistic: additionalContext written as instructions can
# be filtered as prompt injection, which would drop the report without a trace.
report = (
    f"A background subagent is now running unobserved ({agent}: {what}). Nothing in this session "
    "samples its progress until it reports, so a stall, a crash and steady work are currently "
    "indistinguishable. The watch skill exists for this: it samples a cheap external probe so "
    "silence becomes visible progress. What a watch catches is stalling, silence and runaway "
    "duration — not a report that arrives confidently wrong, which stays a matter for verifying "
    "the claims against their cited sources."
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
