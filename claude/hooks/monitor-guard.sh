#!/usr/bin/env bash
# monitor-guard — PreToolUse(Monitor) hook. Prompts the vacuity check on a watch that can
# terminate (see ~/.claude/ENGINEERING-DEFAULTS.md — Watching Long Background Work).
#
# Whether a terminal condition is vacuous is undecidable from the command text, so this asks
# rather than decides: exit 0 always, guidance carried in stdout JSON. Exit 2 would block a
# legitimate watch on a guess.
set -uo pipefail

INPUT="$(cat)"

# A malformed or non-Monitor payload leaves nothing to advise on, and the hook must never
# block on its own failure.
CMD="$(printf '%s' "${INPUT}" |
	python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null || true)"
[[ -z ${CMD} ]] && exit 0

# An unbounded watch has no terminal condition to get wrong.
printf '%s' "${CMD}" | grep -q 'break' || exit 0

python3 <<'PY'
import json

guidance = (
    "This watch has a terminal condition, and a terminal condition is vacuous when it can be "
    "satisfied without the work having caused it. Three shapes account for most of them.\n"
    "The condition already holds at arming time. \"Tests are green\" verifies nothing if the suite "
    "was already green; what separates work from no work is evidence of the transition — RED "
    "observed, a total grown.\n"
    "The condition holds at some intermediate state the work passes through. Agents create "
    "structure early and cheaply, so structure (a file exists, a heading exists) is satisfied long "
    "before substance (counts of sources, tests, assertions). An agent working a list of units, "
    "each ending RED/GREEN/COMMIT, turns the suite green once per unit, so \"stable green\" is true "
    "at unit 1 of N.\n"
    "The condition is silent on failure. A filter that emits nothing once the work has crashed "
    "makes silence and progress identical.\n"
    "In model-checking terms this is antecedent failure, where trivial validity is a reliable "
    "indicator of a real defect rather than a lucky pass. A watch that ends without having observed "
    "the transition has produced an inconclusive result rather than a successful one."
)

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "additionalContext": guidance,
    }
}))
PY
exit 0
