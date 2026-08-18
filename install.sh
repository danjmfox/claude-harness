#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${HOME}/.dotfiles-backup"

ensure_shell_is_zsh() {
	local current
	current="${SHELL-}"

	if [[ -z ${current} ]]; then
		return
	fi

	if [[ $(basename "${current}") != "zsh" ]]; then
		local desired
		desired="$(command -v zsh || true)"
		cat <<EOF >&2
It looks like your login shell is not Zsh (${current}). The dotfiles assume Zsh,
so run this once to switch:

    chsh -s "${desired:-/bin/zsh}" "${USER}"

Then restart your session and rerun ./install.sh.
EOF
		exit 1
	fi
}

is_worktree_checkout() {
	[[ ${DOTFILES_ROOT} == */.claude/worktrees/* ]]
}

ensure_not_worktree_checkout() {
	if is_worktree_checkout; then
		cat <<EOF >&2
Refusing to run: this copy of install.sh lives inside a git worktree.

    ${DOTFILES_ROOT}

DOTFILES_ROOT resolves from the script's own location, so every symlink would
point into the worktree — and later edits on main would then appear to have no
effect. Run the main checkout's copy instead:

    ~/projects/claude-harness/install.sh
EOF
		return 1
	fi
}

declare -a RUNCOMS=(
	zlogin
	zprofile
	zshenv
	zshrc
)
declare -a CONFIG_LINKS=(
	"config/starship/starship.toml:.config/starship.toml"
	"config/direnv/direnv.toml:.config/direnv/direnv.toml"
	"claude/CLAUDE.md:.claude/CLAUDE.md"
	"claude/ENGINEERING-DEFAULTS.md:.claude/ENGINEERING-DEFAULTS.md"
	"claude/PRINCIPLES.md:.claude/PRINCIPLES.md"
	"claude/STYLE.md:.claude/STYLE.md"
	"claude/stack.md:.claude/stack.md"
	"claude/hooks/git-guard.sh:.claude/hooks/git-guard.sh"
	"claude/hooks/monitor-guard.sh:.claude/hooks/monitor-guard.sh"
	"claude/hooks/test-guard.sh:.claude/hooks/test-guard.sh"
	"claude/hooks/agent-guard.sh:.claude/hooks/agent-guard.sh"
)

PROFILE="work"

usage() {
	cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --profile <work|home|personaldev|all>  select which profile-scoped overlay links apply
  --help                     show this message
EOF
}

while (($#)); do
	case "$1" in
	--profile)
		if (($# < 2)); then
			echo "Missing value for --profile" >&2
			usage
			exit 1
		fi
		PROFILE="$2"
		shift 2
		continue
		;;
	--profile=*)
		PROFILE="${1#*=}"
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
	shift
done

PROFILE="$(printf '%s' "${PROFILE}" | tr '[:upper:]' '[:lower:]')"

declare -a SELECTED_PROFILES
case "${PROFILE}" in
always)
	SELECTED_PROFILES=(always)
	;;
work)
	SELECTED_PROFILES=(always work)
	;;
home)
	SELECTED_PROFILES=(always home)
	;;
personaldev)
	SELECTED_PROFILES=(always home personaldev)
	;;
all)
	SELECTED_PROFILES=(always work home personaldev)
	;;
*)
	echo "Unknown profile '${PROFILE}'." >&2
	usage
	exit 1
	;;
esac

link_runcoms() {
	mkdir -p "${BACKUP_DIR}"
	for rc in "${RUNCOMS[@]}"; do
		target="${HOME}/.${rc}"
		source="${DOTFILES_ROOT}/zsh/runcoms/${rc}"

		if [[ ! -e ${source} ]]; then
			continue
		fi

		# shellcheck disable=SC2312
		if [[ -e ${target} && ! -L ${target} ]]; then
			mv "${target}" "${BACKUP_DIR}/${rc}"
		elif [[ -L ${target} && "$(readlink "${target}")" == "${source}" ]]; then
			continue
		else
			rm -f "${target}"
		fi

		ln -s "${source}" "${target}"
	done
}

selected_config_links() {
	local -a specs
	specs=("${CONFIG_LINKS[@]}")

	# Sourced before the profile loop: an overlay may append to CONFIG_LINKS_<profile>.
	# Two paths, matching zshrc's seam: local/links.sh when this is claude-harness's own
	# install.sh (local/ symlinks into dotfiles); links.sh directly when dotfiles' own
	# install.sh is what's running instead, since dotfiles has no local/ pointing at itself.
	local overlay="${DOTFILES_ROOT}/local/links.sh"
	if [[ ! -f ${overlay} ]]; then
		overlay="${DOTFILES_ROOT}/links.sh"
	fi
	if [[ -f ${overlay} ]]; then
		# shellcheck source=/dev/null
		source "${overlay}"
	fi

	local profile profile_array
	for profile in "${SELECTED_PROFILES[@]}"; do
		profile_array="CONFIG_LINKS_${profile}[@]"
		# Absence is the normal case — most profiles add no config links.
		if declare -p "CONFIG_LINKS_${profile}" >/dev/null 2>&1; then
			specs+=("${!profile_array}")
		fi
	done

	if declare -p CONFIG_LINKS_LOCAL >/dev/null 2>&1; then
		specs+=("${CONFIG_LINKS_LOCAL[@]}")
	fi

	printf '%s\n' "${specs[@]}"
}

link_config_files() {
	mkdir -p "${BACKUP_DIR}"
	local -a selected
	while IFS= read -r spec; do
		selected+=("${spec}")
	done < <(selected_config_links)

	for link_spec in ${selected[@]+"${selected[@]}"}; do
		source_rel="${link_spec%%:*}"
		target_rel="${link_spec#*:}"

		source="${DOTFILES_ROOT}/${source_rel}"
		target="${HOME}/${target_rel}"
		backup_file="${BACKUP_DIR}/${target_rel//\//__}"

		if [[ ! -e ${source} ]]; then
			continue
		fi

		mkdir -p "$(dirname "${target}")"

		# shellcheck disable=SC2312
		if [[ -e ${target} && ! -L ${target} ]]; then
			mv "${target}" "${backup_file}"
		elif [[ -L ${target} && "$(readlink "${target}")" == "${source}" ]]; then
			continue
		else
			rm -f "${target}"
		fi

		ln -s "${source}" "${target}"
	done
}

link_claude_skills() {
	local skills_src="${DOTFILES_ROOT}/claude/skills"
	local skills_dest="${HOME}/.claude/skills"

	if [[ ! -d ${skills_src} ]]; then
		return
	fi

	mkdir -p "${skills_dest}"

	for skill_path in "${skills_src}"/*/; do
		[[ -d ${skill_path} ]] || continue
		local name target
		name="$(basename "${skill_path}")"
		target="${skills_dest}/${name}"

		if [[ -e ${target} || -L ${target} ]]; then
			continue
		fi

		ln -s "${skill_path%/}" "${target}"
	done
}

update_plugins() {
	if command -v git >/dev/null 2>&1; then
		git -C "${DOTFILES_ROOT}" submodule update --init --recursive zsh/plugins
	fi
}

setup_node_globals() {
	local script_path="${DOTFILES_ROOT}/scripts/setup-node.sh"
	if [[ -x ${script_path} ]]; then
		"${script_path}"
	fi
}

main() {
	update_plugins
	link_runcoms
	link_config_files
	link_claude_skills
	setup_node_globals
}

if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
	ensure_shell_is_zsh
	ensure_not_worktree_checkout || exit 1
	main "$@"
fi
