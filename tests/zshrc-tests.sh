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

run_test "zshrc defines no claude wrapper without the overlay" test_zshrc_defines_no_claude_wrapper_without_the_overlay
run_test "zshrc sources local/zshrc.local when present" test_zshrc_sources_local_overlay_when_present
run_test "zshrc is silent when local/zshrc.local is absent" test_zshrc_is_silent_when_local_overlay_absent
run_test "zshrc returns zero with the overlay seam removed" test_zshrc_returns_zero_with_overlay_seam_removed

printf '\nTests run: %d, Failures: %d\n' "${TEST_COUNT}" "${FAIL_COUNT}"
((FAIL_COUNT == 0))
