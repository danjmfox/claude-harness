#!/usr/bin/env bash
# git-guard — PreToolUse(Bash) hook. Blocks git operations that violate Git Discipline
# (see ~/.claude/ENGINEERING-DEFAULTS.md). Exit 2 blocks the tool call and shows stderr.
#
# Identity-shared: the rules are about how the user works, not about the machine, so this is
# the same on every Mac. Lives in dotfiles rather than in settings.json because settings.json
# carries machine-specific absolute paths and cannot be symlinked.
set -uo pipefail

INPUT="$(cat)"

# Absence is an expected branch here, not a silenced diagnostic: a malformed or non-Bash
# payload means there is nothing to guard, and the guard must never block on its own failure.
CMD="$(printf '%s' "${INPUT}" |
	python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null || true)"
[[ -z ${CMD} ]] && exit 0

# The hook runs in the session's working directory, which is NOT necessarily the repo the command
# acts on: `cd /elsewhere && git commit` and `git -C /elsewhere commit` both target another repo.
# Resolving from $PWD reported the wrong repo and blocked an exempt one. Parse the target instead,
# falling back to $PWD. This cannot be exhaustive — subshells, later `cd`s in a compound command
# and variable paths all defeat it — so it errs toward $PWD, i.e. toward blocking.
target_dir() {
	local dir=""
	if [[ ${CMD} =~ git[[:space:]]+-C[[:space:]]+([^[:space:]\;\&\|]+) ]]; then
		dir="${BASH_REMATCH[1]}"
	elif [[ ${CMD} =~ ^[[:space:]]*cd[[:space:]]+([^[:space:]\;\&\|]+) ]]; then
		dir="${BASH_REMATCH[1]}"
	fi
	dir="${dir/#\~/${HOME}}"
	if [[ -n ${dir} && -d ${dir} ]]; then
		printf '%s' "${dir}"
	else
		printf '%s' "${PWD}"
	fi
}

TARGET="$(target_dir)"
BRANCH="$(git -C "${TARGET}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo none)"
REPO="$(basename "$(git -C "${TARGET}" rev-parse --show-toplevel 2>/dev/null || echo none)")"

# Repos where working directly on the trunk is accepted practice. Space-separated repo
# basenames in GIT_GUARD_TRUNK_OK; empty by default, so the rule applies everywhere until
# you opt a repo out.
TRUNK_OK=" ${GIT_GUARD_TRUNK_OK-} "

on_trunk() { [[ ${BRANCH} == main || ${BRANCH} == master ]]; }
trunk_exempt() { [[ ${TRUNK_OK} == *" ${REPO} "* ]]; }
matches() { printf '%s' "${CMD}" | grep -Eq "$1"; }
block() {
	printf 'BLOCKED by git-guard: %s\n' "$1" >&2
	printf 'See ~/.claude/ENGINEERING-DEFAULTS.md — Git Discipline.\n' >&2
	exit 2
}

if matches 'git +add +(-A|--all|\.)([[:space:]]|$)'; then
	block 'git add -A / --all / . — stage named paths only, so unrelated files are never swept in'
fi

if matches '(gh +pr|glab +mr) +merge.*--squash'; then
	block 'squash merge — it discards per-commit reasoning and orphans stacked PRs. Use a merge commit or rebase-merge'
fi

if on_trunk && ! trunk_exempt; then
	if matches 'git +commit'; then
		block "commit to ${BRANCH} in ${REPO} — create a branch first"
	fi
	if matches 'git +reset +--hard'; then
		block "git reset --hard on ${BRANCH} — this discards commits; stop and ask"
	fi
fi

# What a force-push endangers is the ref it rewrites, not the branch you stand on — and Git
# Discipline puts you on a branch, so gating this on the current branch protects nothing.
if matches 'git +[^|;&]*push +[^|;&]*(--force|--force-with-lease|-f([[:space:]]|$))' &&
	{ matches '(^|[[:space:]:+])(main|master)([[:space:]]|$)' || on_trunk; }; then
	block "force-push affecting the trunk — never rewrite main's ref"
fi

exit 0
