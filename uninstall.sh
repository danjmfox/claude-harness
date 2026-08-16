#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${HOME}/.dotfiles-backup"

declare -a RUNCOMS=(
	zlogin
	zprofile
	zshenv
	zshrc
)

for rc in "${RUNCOMS[@]}"; do
	target="${HOME}/.${rc}"
	source="${DOTFILES_ROOT}/zsh/runcoms/${rc}"

	# shellcheck disable=SC2312
	if [[ -L ${target} && "$(readlink "${target}")" == "${source}" ]]; then
		rm -f "${target}"
	fi

	if [[ -e "${BACKUP_DIR}/${rc}" ]]; then
		mv "${BACKUP_DIR}/${rc}" "${target}"
	fi
done
