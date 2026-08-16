#!/usr/bin/env bash
# Tests for claude/hooks/monitor-guard.sh.
#
# Unlike git-guard, this hook must never block: it advises on a judgement call the hook cannot
# decide for itself, so exit status is always 0 and the payload travels in stdout JSON.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="${REPO_ROOT}/claude/hooks/monitor-guard.sh"

declare -i RUN=0 FAILED=0

# expect_context <yes|no> <label> <monitor command>
expect_context() {
	local want="$1" label="$2" cmd="$3"
	RUN+=1
	local payload out status ctx got
	payload="$(CMD="${cmd}" python3 -c 'import json,os; print(json.dumps({"tool_name":"Monitor","tool_input":{"command":os.environ["CMD"]}}))')"
	out="$(printf '%s' "${payload}" | bash "${GUARD}" 2>/dev/null)"
	status=$?

	if ((status != 0)); then
		FAILED+=1
		printf 'FAIL: %s — hook exited %d; it must never block\n' "${label}" "${status}"
		return
	fi

	ctx="$(printf '%s' "${out}" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    h = d.get("hookSpecificOutput", {})
    assert h.get("hookEventName") == "PreToolUse"
    print(h.get("additionalContext", ""))
except Exception:
    print("")
' 2>/dev/null)"

	got="no"
	[[ -n ${ctx} ]] && got="yes"

	if [[ ${got} == "${want}" ]]; then
		printf 'PASS: context=%s — %s\n' "${want}" "${label}"
	else
		FAILED+=1
		printf 'FAIL: wanted context=%s got %s — %s\n' "${want}" "${got}" "${label}"
	fi
}

# A watch that can terminate has a terminal condition, and a terminal condition can be vacuous.
# shellcheck disable=SC2016 # fixture is a Monitor command; it must reach the hook unexpanded
expect_context yes "bounded watch breaks out of the loop" \
	'while true; do t=$(pnpm test 2>&1); echo "$t" | grep -q "0 failed" && break; sleep 30; done'

# An unbounded watch has no terminal condition, so prompting would be pure noise. This is the
# discrimination that makes the hook worth having rather than a blanket reminder.
expect_context no "unbounded tail never terminates" \
	'tail -f deploy.log | grep -E --line-buffered "ERROR|Traceback|Killed"'

printf '\n%d run, %d failed\n' "${RUN}" "${FAILED}"
((FAILED == 0))
