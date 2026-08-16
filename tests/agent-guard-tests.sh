#!/usr/bin/env bash
# Tests for claude/hooks/agent-guard.sh.
#
# The load-bearing case is the default one: the Agent tool dispatches in the background unless told
# otherwise, so a hook gated on a true run_in_background value would stay silent on most dispatches
# while still passing any test that only exercised the explicit form.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="${REPO_ROOT}/claude/hooks/agent-guard.sh"

declare -i RUN=0 FAILED=0

# expect_report <yes|no> <label> <tool_input as JSON>
expect_report() {
	local want="$1" label="$2" input="$3"
	RUN+=1
	local payload out status got

	payload="$(I="${input}" python3 -c '
import json, os
print(json.dumps({"tool_name": "Agent", "tool_input": json.loads(os.environ["I"])}))')"

	out="$(printf '%s' "${payload}" | bash "${GUARD}" 2>/dev/null)"
	status=$?

	if ((status != 0)); then
		FAILED+=1
		printf 'FAIL: %s — hook exited %d; it must never block\n' "${label}" "${status}"
		return
	fi

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

# The default dispatch carries no run_in_background key at all and is still asynchronous.
expect_report yes "background by omission" \
	'{"subagent_type": "nw-researcher", "description": "Research harness patterns"}'

expect_report yes "background stated explicitly" \
	'{"subagent_type": "Explore", "description": "Find callers", "run_in_background": true}'

# A synchronous dispatch is observed by construction: the turn blocks until it returns.
expect_report no "synchronous dispatch" \
	'{"subagent_type": "Explore", "description": "Find callers", "run_in_background": false}'

# JSON false and the string "false" both reach hooks in practice, and only one of them is falsy in
# a naive truthiness check.
expect_report no "synchronous, stringly typed" \
	'{"subagent_type": "Explore", "description": "Find callers", "run_in_background": "false"}'

# The report names the agent and the task, so a session dispatching several can tell them apart.
RUN+=1
NAMED="$(printf '%s' '{"tool_name":"Agent","tool_input":{"subagent_type":"nw-researcher","description":"Research harness patterns"}}' |
	bash "${GUARD}" 2>/dev/null |
	python3 -c 'import sys,json; print(json.load(sys.stdin).get("systemMessage",""))' 2>/dev/null)"
if [[ ${NAMED} == *"nw-researcher"* && ${NAMED} == *"Research harness patterns"* ]]; then
	printf 'PASS: report identifies the agent and its task\n'
else
	FAILED+=1
	printf 'FAIL: report did not name the agent and task\n'
fi

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
