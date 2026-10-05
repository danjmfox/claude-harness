#!/usr/bin/env bash
# Tests for claude/hooks/red-gate.sh.
#
# The gate is deterministic: it reads exit-status evidence the harness reports, never the model's
# claims. Each case builds a fixture project in a temp dir, pipes a payload to the hook and asserts
# exit 2 (block) vs 0 (allow), plus the files the hook is the only writer of.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATE="${REPO_ROOT}/claude/hooks/red-gate.sh"

declare -i RUN=0 FAILED=0
# Bare `mktemp -d` ignores TMPDIR on macOS, so the root is created with an explicit template.
ROOT="$(mktemp -d "${TMPDIR:-/tmp}/red-gate-tests.XXXXXX")"
trap 'rm -rf "${ROOT}"' EXIT

new_project() {
	local d
	d="$(mktemp -d "${ROOT}/p.XXXXXX")"
	mkdir -p "${d}/.claude"
	printf '%s' "${d}"
}

# fire <project> <event> <tool> <tool_input_json> — prints the hook's stderr, returns its status.
fire() {
	local project="$1" event="$2" tool="$3" input="$4"
	P="${project}" E="${event}" T="${tool}" I="${input}" python3 -c '
import json, os
print(json.dumps({
    "hook_event_name": os.environ["E"],
    "cwd": os.environ["P"],
    "tool_name": os.environ["T"],
    "tool_input": json.loads(os.environ["I"]),
}))' | { bash "${GATE}" >/dev/null; } 2>&1
}

check() {
	local label="$1" ok="$2"
	RUN+=1
	if [[ ${ok} == yes ]]; then
		printf 'PASS: %s\n' "${label}"
	else
		FAILED+=1
		printf 'FAIL: %s\n' "${label}"
	fi
}

write_config() {
	printf '{"test_command": "npm test|vitest", "gated": ["src/"]}' >"$1/.claude/red-gate.json"
}

test_blocks_gated_edit_without_red() {
	local p err status
	p="$(new_project)"
	write_config "${p}"
	err="$(fire "${p}" PreToolUse Edit "{\"file_path\": \"${p}/src/a.ts\"}")"
	status=$?
	[[ ${status} -eq 2 && ${err} == *WHAT* && ${err} == *WHY* && ${err} == *NEXT* ]]
}

check "gated edit with no recorded failing test is blocked with WHAT/WHY/NEXT" \
	"$(test_blocks_gated_edit_without_red && echo yes || echo no)"

test_inert_without_config() {
	local p
	p="$(new_project)"
	fire "${p}" PreToolUse Edit "{\"file_path\": \"${p}/src/a.ts\"}" >/dev/null
}

check "project without red-gate.json is untouched" \
	"$(test_inert_without_config && echo yes || echo no)"

test_allows_ungated_path() {
	local p
	p="$(new_project)"
	write_config "${p}"
	fire "${p}" PreToolUse Edit "{\"file_path\": \"${p}/tests/a.ts\"}" >/dev/null
}

check "edit outside the gated paths is allowed" \
	"$(test_allows_ungated_path && echo yes || echo no)"

test_failing_test_run_opens_the_gate() {
	local p
	p="$(new_project)"
	write_config "${p}"
	fire "${p}" PostToolUseFailure Bash '{"command": "npm test"}' >/dev/null
	fire "${p}" PreToolUse Edit "{\"file_path\": \"${p}/src/a.ts\"}" >/dev/null
}

check "a failing test run (PostToolUseFailure) opens the gate" \
	"$(test_failing_test_run_opens_the_gate && echo yes || echo no)"

test_unrelated_failure_keeps_gate_shut() {
	local p
	p="$(new_project)"
	write_config "${p}"
	fire "${p}" PostToolUseFailure Bash '{"command": "ls /nonexistent"}' >/dev/null
	! fire "${p}" PreToolUse Edit "{\"file_path\": \"${p}/src/a.ts\"}" >/dev/null
}

check "a failing command that is not the test command does not open the gate" \
	"$(test_unrelated_failure_keeps_gate_shut && echo yes || echo no)"

test_passing_run_closes_the_gate() {
	local p
	p="$(new_project)"
	write_config "${p}"
	fire "${p}" PostToolUseFailure Bash '{"command": "npm test"}' >/dev/null
	fire "${p}" PostToolUse Bash '{"command": "npm test"}' >/dev/null
	! fire "${p}" PreToolUse Edit "{\"file_path\": \"${p}/src/a.ts\"}" >/dev/null
}

check "a passing test run closes the gate again" \
	"$(test_passing_run_closes_the_gate && echo yes || echo no)"

test_bypass_allows_and_is_logged() {
	local p log
	p="$(new_project)"
	write_config "${p}"
	RED_GATE_BYPASS="spike, no test yet" fire "${p}" PreToolUse Edit "{\"file_path\": \"${p}/src/a.ts\"}" >/dev/null || return 1
	log="$(cat "${p}/.claude/red-gate-bypass.jsonl" 2>/dev/null)"
	[[ ${log} == *"spike, no test yet"* && ${log} == *"src/a.ts"* ]]
}

check "a human-set bypass allows the edit and logs reason and path" \
	"$(test_bypass_allows_and_is_logged && echo yes || echo no)"

test_state_file_is_hook_written_only() {
	local p
	p="$(new_project)"
	write_config "${p}"
	fire "${p}" PostToolUseFailure Bash '{"command": "npm test"}' >/dev/null
	! fire "${p}" PreToolUse Write "{\"file_path\": \"${p}/.claude/red-gate-state.json\"}" >/dev/null
}

check "the model cannot write the state file even with the gate open" \
	"$(test_state_file_is_hook_written_only && echo yes || echo no)"

printf '\n%d run, %d failed\n' "${RUN}" "${FAILED}"
((FAILED == 0))
