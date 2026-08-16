#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
MANIFEST_PATH="${REPO_ROOT}/config/target-state.sh"

usage() {
	cat <<EOF
Usage: $(basename "$0") [--manifest path]

Checks machine state against the target-state manifest.
EOF
}

while (($#)); do
	case "$1" in
	--manifest)
		if (($# < 2)); then
			echo "Missing value for --manifest" >&2
			usage
			exit 1
		fi
		MANIFEST_PATH="$2"
		shift 2
		;;
	--manifest=*)
		MANIFEST_PATH="${1#*=}"
		shift
		;;
	--help | -h)
		usage
		exit 0
		;;
	*)
		echo "Unknown option: $1" >&2
		usage
		exit 1
		;;
	esac
done

if [[ ! -f ${MANIFEST_PATH} ]]; then
	echo "Manifest not found: ${MANIFEST_PATH}" >&2
	exit 1
fi

declare -i ISSUES=0
declare -a REQUIRED_SYMLINKS=()

# shellcheck disable=SC1090
source "${MANIFEST_PATH}"

ok() {
	printf 'OK   %s\n' "$1"
}

fail() {
	printf 'FAIL %s\n' "$1"
	ISSUES+=1
}

check_command() {
	local cmd="$1"
	if command -v "${cmd}" >/dev/null 2>&1; then
		ok "command available: ${cmd}"
	else
		fail "missing command: ${cmd}"
	fi
}

check_brew_formula() {
	local formula="$1"
	if brew list --formula "${formula}" >/dev/null 2>&1; then
		ok "brew formula installed: ${formula}"
	else
		fail "missing brew formula: ${formula}"
	fi
}

check_brew_cask() {
	local cask="$1"
	if brew list --cask "${cask}" >/dev/null 2>&1; then
		ok "brew cask installed: ${cask}"
	else
		fail "missing brew cask: ${cask}"
	fi
}

check_mise_tool() {
	local spec="$1"
	local tool="${spec%@*}"
	local expected="${spec#*@}"
	local current_line current_version

	if ! current_line="$(mise current "${tool}" 2>/dev/null | head -n1)"; then
		fail "mise tool not active: ${spec}"
		return
	fi

	current_version="$(printf '%s\n' "${current_line}" | grep -Eo '[0-9]+([.][0-9]+)+' | head -n1 || true)"

	if [[ -z ${current_version} ]]; then
		fail "mise tool not active: ${spec}"
		return
	fi

	if [[ ${current_version} == "${expected}"* ]]; then
		ok "mise ${tool} matches ${expected} (current: ${current_version})"
	else
		fail "mise ${tool} expected ${expected}, got ${current_version}"
	fi
}

check_symlink() {
	local link_path="$1"
	local expected_target="$2"
	if [[ ! -L ${link_path} ]]; then
		fail "symlink missing: ${link_path}"
		return
	fi
	local actual_target
	actual_target="$(readlink "${link_path}")"
	if [[ ${actual_target} == "${expected_target}" ]]; then
		ok "symlink: ${link_path} -> ${expected_target}"
	else
		fail "symlink: ${link_path} -> ${actual_target} (expected ${expected_target})"
	fi
}

check_node_global_packages() {
	local file_path="$1"
	local pkg

	if [[ -z ${file_path} ]]; then
		return
	fi

	if [[ ! -f ${file_path} ]]; then
		fail "node globals file missing: ${file_path}"
		return
	fi

	while IFS= read -r pkg; do
		pkg="${pkg//[[:space:]]/}"
		[[ -z ${pkg} || ${pkg:0:1} == "#" ]] && continue

		if mise exec -- npm list -g --depth=0 "${pkg}" >/dev/null 2>&1; then
			ok "npm global installed: ${pkg}"
		else
			fail "missing npm global: ${pkg}"
		fi
	done <"${file_path}"
}

echo "== Dotfiles Doctor =="
echo "Manifest: ${MANIFEST_PATH}"

for cmd in "${REQUIRED_COMMANDS[@]}"; do
	check_command "${cmd}"
done

if ((${#REQUIRED_BREW_FORMULAE[@]} > 0 || ${#REQUIRED_BREW_CASKS[@]} > 0)); then
	if command -v brew >/dev/null 2>&1; then
		for formula in "${REQUIRED_BREW_FORMULAE[@]}"; do
			check_brew_formula "${formula}"
		done
		for cask in "${REQUIRED_BREW_CASKS[@]}"; do
			check_brew_cask "${cask}"
		done
	else
		fail "brew is required for formula/cask checks but is not installed"
	fi
fi

if ((${#REQUIRED_MISE_TOOLS[@]} > 0)); then
	if command -v mise >/dev/null 2>&1; then
		for spec in "${REQUIRED_MISE_TOOLS[@]}"; do
			check_mise_tool "${spec}"
		done
	else
		fail "mise is required for runtime checks but is not installed"
	fi
fi

if [[ -n ${NODE_GLOBAL_PACKAGES_FILE-} ]]; then
	check_node_global_packages "${REPO_ROOT}/${NODE_GLOBAL_PACKAGES_FILE}"
fi

for symlink_spec in "${REQUIRED_SYMLINKS[@]}"; do
	check_symlink "${symlink_spec%%:*}" "${symlink_spec#*:}"
done

echo
if ((ISSUES > 0)); then
	printf 'Doctor result: %d issue(s) found.\n' "${ISSUES}"
	exit 1
fi

echo "Doctor result: healthy."
