#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
PACKAGES_FILE="${DOTFILES_ROOT}/node/global-packages.txt"

# shellcheck source-path=SCRIPTDIR
# shellcheck source=../config/target-state.sh
. "${DOTFILES_ROOT}/config/target-state.sh"
NODE_VERSION="${DOTFILES_NODE_VERSION:-${NODE_VERSION}}"

if [[ ! -f ${PACKAGES_FILE} ]]; then
	exit 0
fi

if ! command -v mise >/dev/null 2>&1; then
	echo "mise not found; skipping Node global package install."
	exit 0
fi

mise use -g "node@${NODE_VERSION}" >/dev/null

while IFS= read -r pkg; do
	pkg="${pkg//[[:space:]]/}"
	[[ -z ${pkg} || ${pkg:0:1} == "#" ]] && continue

	if mise exec -- npm list -g --depth=0 "${pkg}" >/dev/null 2>&1; then
		continue
	fi

	mise exec -- npm install -g "${pkg}"
done <"${PACKAGES_FILE}"
