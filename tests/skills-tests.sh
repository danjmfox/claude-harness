#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

declare -i TEST_COUNT=0
declare -i FAIL_COUNT=0

run_test() {
	local name="$1"
	shift
	TEST_COUNT+=1
	if "$@"; then
		printf 'PASS: %s\n' "${name}"
	else
		FAIL_COUNT+=1
		printf 'FAIL: %s\n' "${name}"
	fi
}

# @walking_skeleton @driving_port (bash-harness equivalent of the Gherkin tag).
# E2E: run the bundled skill script the way Claude would, on the committed
# synthetic Miro-shape fixture, and assert it reconstructs the three-tier
# story map (journey -> step -> swimlane -> card) as JSON.
#
# The single acceptance assertion exercises every load-bearing behaviour:
#   - affine transform-stack composition (card absolute x/y from nested <g>),
#   - card-field parsing (status / jira_key / commit_ref / title) incl. the
#     faithful title wart (jira key retained when no "- sha" precedes it),
#   - the journey tier the Python reference flattens away,
#   - the deliberate "Platform" journey-vs-step name overlap.
#
# Deletion check: break or remove extract.mjs and this test fails.
test_miro_storymap_two_tier_extract() {
	local skill_dir="${REPO_ROOT}/claude/skills/miro-storymap-extract"
	local out
	out="$(node "${skill_dir}/scripts/extract.mjs" "${skill_dir}/fixtures/story-map.svg")" || return 1

	node -e '
		const assert = require("node:assert");
		const fs = require("node:fs");
		const d = JSON.parse(fs.readFileSync(0, "utf8"));

		// Journey tier (names + their ordered step names). "Platform" appears as
		// both a journey and a step — proves the two are tracked independently.
		const journeys = d.journeys.map((j) => ({ name: j.name, steps: j.steps.map((s) => s.name) }));
		assert.deepStrictEqual(journeys, [
			{ name: "Platform", steps: ["Platform", "Agents"] },
			{ name: "Session Management", steps: ["Session", "New task"] },
		], "journeys/steps");

		assert.deepStrictEqual(d.swimlanes, ["Walking Skeleton", "MVP"], "swimlanes");
		assert.deepStrictEqual(d.counts, { journeys: 2, steps: 4, swimlanes: 2, cards: 4 }, "counts");

		// One card asserted whole: transforms (x/y), field parsing, and all three
		// axis assignments — and no extra keys leak (raw/internal fields excluded).
		const auth = d.cards.find((c) => c.title === "Auth flow");
		assert.deepStrictEqual(auth, {
			journey: "Platform", step: "Platform", swimlane: "Walking Skeleton",
			title: "Auth flow", jira_key: "AVA-5532", commit_ref: "94fe8d3 (#191)",
			status: "Done", x: 120, y: 200,
		}, "auth card");

		// Faithful port of the title heuristic: no "- sha" => jira key stays in title.
		const agent = d.cards.find((c) => c.step === "Agents");
		assert.strictEqual(agent.title, "Agent list AVA-5550", "agent title fidelity");
		assert.strictEqual(agent.commit_ref, "", "agent has no commit");
	' <<<"${out}"
}

# @driving_port @error — contract regression (locks the SKILL.md "Errors" clause for
# existing behaviour): the CLI exits 2 on a missing path argument and non-zero on an
# unreadable file, so the documented contract cannot silently regress.
test_miro_storymap_extract_error_paths() {
	local skill_dir="${REPO_ROOT}/claude/skills/miro-storymap-extract"
	local code

	code=0
	node "${skill_dir}/scripts/extract.mjs" >/dev/null 2>&1 || code=$?
	[[ ${code} -eq 2 ]] || {
		printf '  missing-arg exit=%s (want 2)\n' "${code}"
		return 1
	}

	code=0
	node "${skill_dir}/scripts/extract.mjs" "${skill_dir}/does-not-exist.svg" >/dev/null 2>&1 || code=$?
	[[ ${code} -ne 0 ]] || {
		printf '  missing-file exit=%s (want non-zero)\n' "${code}"
		return 1
	}
}

run_test "miro-storymap-extract: SVG -> three-tier story-map JSON" test_miro_storymap_two_tier_extract
run_test "miro-storymap-extract: error paths (missing arg -> 2, unreadable -> non-zero)" test_miro_storymap_extract_error_paths

printf '\n%d run, %d failed\n' "${TEST_COUNT}" "${FAIL_COUNT}"
[[ ${FAIL_COUNT} -eq 0 ]]
