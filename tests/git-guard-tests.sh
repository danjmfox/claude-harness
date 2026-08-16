#!/usr/bin/env bash
# Tests for claude/hooks/git-guard.sh.
#
# Fixtures live in this file rather than inline in a shell command on purpose: the guard matches the
# literal text of the command it is given, so a command that merely *mentions* a blocked pattern is
# itself blocked. That is inherent to a text matcher and is the documented limitation, not a bug to
# fix here — but it does mean tests must not pass fixtures on a command line.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="${REPO_ROOT}/claude/hooks/git-guard.sh"

declare -i RUN=0 FAILED=0

# expect <blocked|allowed> <cwd> <command...>
expect() {
	local want="$1" cwd="$2" cmd="$3"
	RUN+=1
	local payload status
	payload="$(CMD="${cmd}" python3 -c 'import json,os; print(json.dumps({"tool_input":{"command":os.environ["CMD"]}}))')"
	(cd "${cwd}" && printf '%s' "${payload}" | bash "${GUARD}" >/dev/null 2>&1)
	status=$?
	local got="allowed"
	((status == 2)) && got="blocked"

	if [[ ${got} == "${want}" ]]; then
		printf 'PASS: %s (%s) — %s\n' "${want}" "$(basename "${cwd}")" "${cmd:0:52}"
	else
		FAILED+=1
		printf 'FAIL: wanted %s got %s (%s) — %s\n' "${want}" "${got}" "$(basename "${cwd}")" "${cmd:0:52}"
	fi
}

# expect_quiet <cwd> <command> — an allowed command must produce no diagnostic of the guard's own.
# `expect` above sends stderr to /dev/null, which is how a set -u failure inside target_dir stayed
# invisible: the guard still exited 0, so every assertion kept passing while the $PWD fallback it
# was meant to reach never ran.
expect_quiet() {
	local cwd="$1" cmd="$2"
	RUN+=1
	local payload err
	payload="$(CMD="${cmd}" python3 -c 'import json,os; print(json.dumps({"tool_input":{"command":os.environ["CMD"]}}))')"
	err="$(cd "${cwd}" && printf '%s' "${payload}" | bash "${GUARD}" 2>&1 >/dev/null)"

	if [[ -n ${err} ]]; then
		FAILED+=1
		printf 'FAIL: guard emitted its own diagnostic — %s\n' "${err#*git-guard.sh: }"
	else
		printf 'PASS: no internal diagnostic — %s\n' "${cmd:0:44}"
	fi
}

DOTFILES="${REPO_ROOT}"
# A throwaway repo, created rather than assumed. This used to point at a repo that happened
# to exist on one machine, so the three cross-repo assertions below ran there and were
# skipped everywhere else — silently, because the suite still reported 0 failures.
OTHER="$(mktemp -d)/other-repo"
mkdir -p "${OTHER}"
# -b main: the trunk rule only fires on main/master, and a fresh init may default elsewhere.
# An empty repo has no HEAD to resolve, so on_trunk() would see "none" — commit once.
git -C "${OTHER}" init -q -b main 2>/dev/null
git -C "${OTHER}" -c user.email=test@test -c user.name=test commit -q --allow-empty -m init 2>/dev/null
cleanup_other() { rm -rf "$(dirname "${OTHER}")"; }
trap cleanup_other EXIT

# Staging discipline — everywhere, regardless of repo or branch.
expect blocked "${DOTFILES}" 'git add -A'
expect blocked "${DOTFILES}" 'git add --all'
expect blocked "${DOTFILES}" 'git add .'
expect allowed "${DOTFILES}" 'git add src/foo.js'
expect allowed "${DOTFILES}" 'git add .gitignore'

# Trunk commits: dotfiles is exempt, other repos are not.
expect allowed "${DOTFILES}" 'git commit -m x'
if [[ -d ${OTHER}/.git ]]; then
	expect blocked "${OTHER}" 'git commit -m x'
	# The target is parsed from the command, not taken from $PWD — this is the case that
	# originally misfired, reporting the cwd's repo while acting on an exempt one.
	expect allowed "${OTHER}" "cd ${DOTFILES} && git commit -m x"
	expect allowed "${OTHER}" "git -C ${DOTFILES} commit -m x"
fi

# Force-pushing the trunk is never exempt, not even in dotfiles.
expect blocked "${DOTFILES}" 'git push --force origin main'
expect allowed "${DOTFILES}" 'git push origin main'

# What a force-push endangers is the ref it rewrites, not the branch you happen to stand on.
# /tmp is not a repo, so BRANCH resolves to none — exactly the case a current-branch check waves
# through, and the normal case given Git Discipline says to work on a branch.
expect blocked "${DOTFILES}" 'git -C /tmp push --force origin main'
expect blocked "${DOTFILES}" 'git -C /tmp push -f origin HEAD:master'
expect allowed "${DOTFILES}" 'git -C /tmp push --force origin my-feature-branch'

# Neither `cd` nor `git -C`, so target_dir has to reach its $PWD fallback. That path is the one
# the comment above it claims errs toward blocking, so it must actually execute.
expect_quiet "${DOTFILES}" 'git status'

printf '\n%d run, %d failed\n' "${RUN}" "${FAILED}"
((FAILED == 0))
