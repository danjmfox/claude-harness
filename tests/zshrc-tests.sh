#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TEMP_DIRS=()

cleanup() {
	for dir in ${TEMP_DIRS[@]+"${TEMP_DIRS[@]}"}; do
		rm -rf "${dir}"
	done
}

trap cleanup EXIT

abort_no_temp_dirs() {
	printf 'FATAL: mktemp -d is unavailable: %s\n' "$1" >&2
	printf 'Tests build a throwaway DOTFILES tree; without one the fixtures would\n' >&2
	printf 'land in the repo. Re-run from a terminal outside the sandbox.\n' >&2
}

require_temp_dirs() {
	local probe
	if ! probe="$(mktemp -d 2>&1)" || [[ -z ${probe} ]]; then
		abort_no_temp_dirs "${probe:-no output}"
		exit 1
	fi
	rm -rf "${probe}"
}

require_temp_dirs

require_zsh() {
	if ! command -v zsh >/dev/null 2>&1; then
		printf 'FATAL: zsh is not installed; these tests exercise zshrc directly.\n' >&2
		exit 1
	fi
}

require_zsh

add_temp_dir() {
	local dir
	if ! dir="$(mktemp -d 2>&1)" || [[ -z ${dir} ]]; then
		abort_no_temp_dirs "${dir:-no output}"
		kill -TERM $$
	fi
	TEMP_DIRS+=("${dir}")
	printf '%s' "${dir}"
}

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

# A throwaway DOTFILES tree holding the real zshrc plus the minimum around it:
# empty plugin files to satisfy its three unconditional `source` lines, and stubs
# for the tools it evals. Everything else in zshrc is setopt/bindkey, which is
# inert in a non-interactive shell.
make_fixture_dotfiles() {
	local root="$1"
	local plugin

	mkdir -p "${root}/zsh/runcoms"
	cp "${REPO_ROOT}/zsh/runcoms/zshrc" "${root}/zsh/runcoms/zshrc"

	for plugin in zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting; do
		mkdir -p "${root}/zsh/plugins/${plugin}"
		: >"${root}/zsh/plugins/${plugin}/${plugin}.zsh"
	done

	mkdir -p "${root}/stub-bin"
	for tool in starship mise; do
		printf '#!/bin/sh\nexit 0\n' >"${root}/stub-bin/${tool}"
		chmod +x "${root}/stub-bin/${tool}"
	done
}

# Delete the overlay-seam block from a fixture zshrc, so whatever precedes it
# becomes the last statement and its status becomes zshrc's status. The seam is
# an `if`, which returns 0 whether or not it fires, so it masks a failing
# trailing `cond && cmd` above it from every assertion in this file.
strip_overlay_seam() {
	local zshrc="$1"
	local stripped="${zshrc}.stripped"

	awk '
		/^# Optional overlay seam/ { skipping = 1 }
		skipping && /^fi$/ { skipping = 0; next }
		!skipping
	' "${zshrc}" >"${stripped}"

	# Match the statement, not the string: prose elsewhere in zshrc mentions the
	# seam by name, and a bare grep reports it as a surviving seam.
	if ! grep -qE '^[[:space:]]*source .*local/zshrc\.local' "${zshrc}"; then
		printf '  fixture zshrc has no overlay seam to strip\n' >&2
		return 1
	fi
	if grep -qE '^[[:space:]]*source .*local/zshrc\.local' "${stripped}"; then
		printf '  overlay seam survived stripping\n' >&2
		return 1
	fi

	mv "${stripped}" "${zshrc}"
}

# Source the fixture zshrc in a clean zsh and report the marker plus stderr.
# Marker is set only by local/zshrc.local, so it proves the seam fired.
source_fixture_zshrc() {
	local root="$1"
	local err_file="$2"

	# RC is captured immediately: a trailing `[[ -f x ]] && source x` returns
	# non-zero when x is absent, and any later command would mask it.
	HOME="${root}/home" \
		DOTFILES="${root}" \
		PATH="${root}/stub-bin:${PATH}" \
		zsh -f -c "
			export DOTFILES='${root}'
			source '${root}/zsh/runcoms/zshrc'
			rc=\$?
			print -r -- \"MARKER=\${OVERLAY_MARKER-unset}\"
			print -r -- \"RC=\${rc}\"
		" 2>"${err_file}"
}

test_zshrc_sources_local_overlay_when_present() {
	local root out err
	root="$(add_temp_dir)"
	make_fixture_dotfiles "${root}"
	mkdir -p "${root}/home" "${root}/local"
	printf 'OVERLAY_MARKER=fired\n' >"${root}/local/zshrc.local"

	err="${root}/stderr"
	out="$(source_fixture_zshrc "${root}" "${err}" || true)"

	if [[ ${out} != *"MARKER=fired"* ]]; then
		printf '  expected MARKER=fired, got: %s\n' "${out}" >&2
		return 1
	fi

	return 0
}

test_zshrc_is_silent_when_local_overlay_absent() {
	local root out err status
	root="$(add_temp_dir)"
	make_fixture_dotfiles "${root}"
	mkdir -p "${root}/home"

	err="${root}/stderr"
	status=0
	out="$(source_fixture_zshrc "${root}" "${err}")" || status=$?

	if ((status != 0)); then
		printf '  zshrc exited %d with no overlay present\n' "${status}" >&2
		return 1
	fi
	if [[ ${out} != *"RC=0"* ]]; then
		printf '  sourcing zshrc returned non-zero: %s\n' "${out}" >&2
		return 1
	fi
	# An unguarded source of the absent seam reports "no such file" here and
	# nowhere else — zshrc keeps going, so stderr is the only witness.
	if [[ -s ${err} ]]; then
		printf '  expected silence, got: %s\n' "$(head -2 "${err}")" >&2
		return 1
	fi
	if [[ ${out} != *"MARKER=unset"* ]]; then
		printf '  expected MARKER=unset, got: %s\n' "${out}" >&2
		return 1
	fi

	return 0
}

test_zshrc_defines_no_claude_wrapper_without_the_overlay() {
	local root out err
	root="$(add_temp_dir)"
	make_fixture_dotfiles "${root}"
	mkdir -p "${root}/home"

	err="${root}/stderr"
	out="$(
		HOME="${root}/home" DOTFILES="${root}" PATH="${root}/stub-bin:${PATH}" \
			zsh -f -c "
				export DOTFILES='${root}'
				source '${root}/zsh/runcoms/zshrc'
				print -r -- \"CLAUDE_FN=\${\$(whence -w claude 2>/dev/null):-none}\"
			" 2>"${err}" || true
	)"

	# The telemetry wrapper is employer content. A bare checkout must not carry it.
	if [[ ${out} == *"claude: function"* ]]; then
		printf '  zshrc defined a claude() wrapper with no overlay present\n' >&2
		return 1
	fi

	return 0
}

test_zshrc_returns_zero_with_overlay_seam_removed() {
	local root out err status
	root="$(add_temp_dir)"
	make_fixture_dotfiles "${root}"
	mkdir -p "${root}/home"
	strip_overlay_seam "${root}/zsh/runcoms/zshrc" || return 1

	err="${root}/stderr"
	status=0
	out="$(source_fixture_zshrc "${root}" "${err}")" || status=$?

	if ((status != 0)); then
		printf '  zshrc exited %d with the overlay seam removed\n' "${status}" >&2
		return 1
	fi
	if [[ ${out} != *"RC=0"* ]]; then
		printf '  sourcing zshrc returned non-zero: %s\n' "${out}" >&2
		return 1
	fi
	if [[ -s ${err} ]]; then
		printf '  expected silence, got: %s\n' "$(head -2 "${err}")" >&2
		return 1
	fi

	return 0
}

# Source the fixture zshrc from inside DIR and print whatever it wrote to stdout,
# where the terminal escape sequences land.
zshrc_stdout_from() {
	local root="$1"
	local dir="$2"

	HOME="${root}/home" DOTFILES="${root}" PATH="${root}/stub-bin:${PATH}" \
		zsh -f -c "
			export DOTFILES='${root}'
			cd '${dir}'
			source '${root}/zsh/runcoms/zshrc'
		" 2>/dev/null
}

make_git_repo() {
	local dir="$1"
	mkdir -p "${dir}"
	git -C "${dir}" init -q
}

test_zshrc_sets_background_colour_inside_a_git_repo() {
	local root repo out
	root="$(add_temp_dir)"
	make_fixture_dotfiles "${root}"
	mkdir -p "${root}/home"
	repo="${root}/proj"
	make_git_repo "${repo}"

	out="$(zshrc_stdout_from "${root}" "${repo}" || true)"

	if [[ ${out} != *$'\e]11;#'[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]* ]]; then
		printf '  expected an OSC 11 background colour, got: %q\n' "${out}" >&2
		return 1
	fi

	return 0
}

osc11_colour() {
	local out="$1"
	[[ ${out} =~ $'\e]11;#'([0-9a-f]{6}) ]] || return 1
	printf '%s' "${BASH_REMATCH[1]}"
}

test_zshrc_gives_each_worktree_its_own_colour() {
	local root main wt out_main out_wt
	root="$(add_temp_dir)"
	make_fixture_dotfiles "${root}"
	mkdir -p "${root}/home"
	main="${root}/main"
	make_git_repo "${main}"
	git -C "${main}" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
	wt="${root}/wt"
	git -C "${main}" worktree add -q -b other "${wt}"

	out_main="$(osc11_colour "$(zshrc_stdout_from "${root}" "${main}")")" || return 1
	out_wt="$(osc11_colour "$(zshrc_stdout_from "${root}" "${wt}")")" || return 1

	if [[ ${out_main} == "${out_wt}" ]]; then
		printf '  main checkout and its worktree share colour %s\n' "${out_main}" >&2
		return 1
	fi

	return 0
}

test_zshrc_restores_background_outside_a_git_repo() {
	local root plain out
	root="$(add_temp_dir)"
	make_fixture_dotfiles "${root}"
	mkdir -p "${root}/home" "${root}/plain"
	plain="${root}/plain"

	out="$(zshrc_stdout_from "${root}" "${plain}" || true)"

	if [[ ${out} != *$'\e]111'* ]]; then
		printf '  expected an OSC 111 reset, got: %q\n' "${out}" >&2
		return 1
	fi

	return 0
}

test_zshrc_recolours_on_cd_into_a_repo() {
	local root repo out
	root="$(add_temp_dir)"
	make_fixture_dotfiles "${root}"
	mkdir -p "${root}/home" "${root}/plain"
	repo="${root}/proj"
	make_git_repo "${repo}"

	out="$(
		HOME="${root}/home" DOTFILES="${root}" PATH="${root}/stub-bin:${PATH}" \
			zsh -f -c "
				export DOTFILES='${root}'
				cd '${root}/plain'
				source '${root}/zsh/runcoms/zshrc'
				printf 'AFTER_SOURCE\n'
				cd '${repo}'
			" 2>/dev/null || true
	)"

	if [[ ${out##*AFTER_SOURCE} != *$'\e]11;#'* ]]; then
		printf '  cd into a repo emitted no OSC 11: %q\n' "${out##*AFTER_SOURCE}" >&2
		return 1
	fi

	return 0
}

run_test "zshrc defines no claude wrapper without the overlay" test_zshrc_defines_no_claude_wrapper_without_the_overlay
run_test "zshrc sources local/zshrc.local when present" test_zshrc_sources_local_overlay_when_present
run_test "zshrc is silent when local/zshrc.local is absent" test_zshrc_is_silent_when_local_overlay_absent
run_test "zshrc returns zero with the overlay seam removed" test_zshrc_returns_zero_with_overlay_seam_removed
run_test "zshrc sets a background colour inside a git repo" test_zshrc_sets_background_colour_inside_a_git_repo
run_test "zshrc gives each worktree its own colour" test_zshrc_gives_each_worktree_its_own_colour
run_test "zshrc restores the background outside a git repo" test_zshrc_restores_background_outside_a_git_repo
run_test "zshrc recolours on cd into a repo" test_zshrc_recolours_on_cd_into_a_repo

printf '\nTests run: %d, Failures: %d\n' "${TEST_COUNT}" "${FAIL_COUNT}"
((FAIL_COUNT == 0))
