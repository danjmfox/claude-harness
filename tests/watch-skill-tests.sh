#!/usr/bin/env bash
# Tests for claude/skills/watch/SKILL.md.
#
# The recipes are extracted from the SKILL.md rather than copied here: they are the shipped
# artifact, and a copy would drift. Probes are stubbed on PATH and driven by a tick counter, so a
# scripted sequence of suite states runs in milliseconds.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="${REPO_ROOT}/claude/skills/watch/SKILL.md"
WORK="${TMPDIR:-/tmp}/watch-skill-tests.$$"
CAP=12

declare -i RUN=0 FAILED=0

cleanup() { rm -rf "${WORK}"; }
trap cleanup EXIT

build_stubs() {
	local bin="${WORK}/bin"
	mkdir -p "${bin}"

	cat >"${WORK}/seq.sh" <<'EOF'
# Suite line by tick, per scenario. `perunit` lands two units then the third; ticks 2 and 4 are
# green *mid-run* — the states a naive "stop when green" condition mistakes for completion.
tests_for_tick() {
	case "${MODE}:$1" in
	green:*) printf ' Tests  18 passed (18)' ;;
	r1seq:1 | r1seq:2) printf ' Tests  2 failed | 10 passed (12)' ;;
	r1seq:*) printf ' Tests  12 passed (12)' ;;
	perunit:1) printf ' Tests  2 failed | 10 passed (12)' ;;
	perunit:2) printf ' Tests  12 passed (12)' ;;
	perunit:3) printf ' Tests  3 failed | 12 passed (15)' ;;
	perunit:4) printf ' Tests  15 passed (15)' ;;
	*) printf ' Tests  18 passed (18)' ;;
	esac
}
commits_for_tick() {
	case "$1" in
	1) printf '0' ;;
	2 | 3) printf '1' ;;
	4) printf '2' ;;
	*) printf '3' ;;
	esac
}
EOF

	cat >"${bin}/pnpm" <<EOF
#!/usr/bin/env bash
source "${WORK}/seq.sh"
tests_for_tick "\$(cat "${WORK}/tick")"
EOF
	cat >"${bin}/git" <<EOF
#!/usr/bin/env bash
source "${WORK}/seq.sh"
printf '%d\n' \$(( 100 + \$(commits_for_tick "\$(cat "${WORK}/tick")") ))
EOF
	# Only sleep advances the tick, so one tick == one loop iteration. A recipe that never
	# terminates must fail the test rather than hang it, hence the cap.
	cat >"${bin}/sleep" <<EOF
#!/usr/bin/env bash
t=\$(cat "${WORK}/tick")
printf '%d' \$(( t + 1 )) > "${WORK}/tick"
if (( t >= ${CAP} )); then
	echo "RUNAWAY — recipe did not terminate"
	kill -TERM \$PPID
fi
exit 0
EOF
	chmod +x "${bin}/pnpm" "${bin}/git" "${bin}/sleep"
}

# Pulls the Nth ```bash fenced block out of the SKILL.md.
extract_recipe() {
	awk -v want="$1" '
		/^```bash$/ { n++; if (n == want) { inb = 1; next } }
		/^```$/     { inb = 0 }
		inb         { print }
	' "${SKILL}"
}

# run_recipe <script> <mode> -> sets OUT and END_TICK
# shellcheck disable=SC2034 # END_TICK is read inside the conditions eval'd by check()
run_recipe() {
	printf '1' >"${WORK}/tick"
	OUT="$(MODE="$2" PATH="${WORK}/bin:${PATH}" bash "$1" 2>&1)"
	END_TICK="$(cat "${WORK}/tick")"
}

check() {
	local label="$1" cond="$2"
	RUN+=1
	if eval "${cond}"; then
		printf 'PASS: %s\n' "${label}"
	else
		FAILED+=1
		printf 'FAIL: %s\n' "${label}"
	fi
}

rm -rf "${WORK}"
build_stubs

TESTS_RECIPE="${WORK}/test-count.sh"
UNIT_RECIPE="${WORK}/per-unit.sh"
extract_recipe 1 >"${TESTS_RECIPE}"
extract_recipe 2 | sed 's/STEPS=12/STEPS=3/' >"${UNIT_RECIPE}"

check "test-count recipe extracted" "[[ -s ${TESTS_RECIPE} ]]"
check "per-unit recipe extracted and parameterised to 3 steps" "grep -q 'STEPS=3' ${UNIT_RECIPE}"

# --- test-count recipe: the vacuity guard -------------------------------------------------
# An already-green suite is antecedent failure: the terminal condition is satisfied without the
# work having caused anything. The recipe must refuse to call it success.
run_recipe "${TESTS_RECIPE}" green
printf -- '--- test-count, already green ---\n%s\n' "${OUT}"
check "already-green suite is reported inconclusive" "grep -q 'inconclusive' <<<\"\${OUT}\""
check "already-green suite never claims success" "! grep -q 'RED preceded GREEN' <<<\"\${OUT}\""
# Emit-on-change applies to every branch, including the ones that report a problem: a state
# repeated each sample is notification spam and gets the monitor suppressed.
check "inconclusive is emitted once, not per sample" "(( \$(grep -c 'inconclusive' <<<\"\${OUT}\") == 1 ))"

run_recipe "${TESTS_RECIPE}" r1seq
printf -- '--- test-count, red then green ---\n%s\n' "${OUT}"
check "RED then GREEN terminates successfully" "grep -q 'RED preceded GREEN' <<<\"\${OUT}\""
check "RED state was reported on the way" "grep -q 'RED 2 failing' <<<\"\${OUT}\""
check "terminated before the runaway cap" "(( END_TICK < CAP ))"

# --- per-unit recipe: the recurring-intermediate-state guard ----------------------------
run_recipe "${UNIT_RECIPE}" perunit
printf -- '--- per-unit ---\n%s\n' "${OUT}"
check "reports intermediate progress per step" "grep -q 'step 1/3' <<<\"\${OUT}\""
check "does NOT stop at the mid-run green on tick 2" "(( END_TICK > 2 ))"
check "reaches the real terminal state" "grep -q 'ALL 3 STEPS DONE' <<<\"\${OUT}\""
check "ends deliberately, not by runaway" "grep -q 'all steps complete' <<<\"\${OUT}\""

# --- the vacuity proof ---------------------------------------------------------------------
# The same probe with a terminal condition of "green" alone must stop mid-run, having
# verified nothing. If this ever stops firing early, the scenario stopped exercising the trap
# and every check above proves less than it appears to.
cat >"${WORK}/naive.sh" <<'EOF'
while true; do
  line=$(pnpm test 2>&1 | grep -E '^ *Tests +' | tail -1)
  fail=$(printf '%s' "$line" | grep -oE '[0-9]+ failed' | grep -oE '[0-9]+' || echo 0)
  [ "$fail" -eq 0 ] && { echo "GREEN — declaring done"; break; }
  sleep 60
done
EOF
run_recipe "${WORK}/naive.sh" perunit
check "vacuous 'stop on green' fires mid-run at tick 2" "(( END_TICK == 2 ))"
check "vacuous condition claims success" "grep -q 'declaring done' <<<\"\${OUT}\""

printf '\n%d run, %d failed\n' "${RUN}" "${FAILED}"
((FAILED == 0))
