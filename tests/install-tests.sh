#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${REPO_ROOT}/install.sh"

TEMP_DIRS=()

cleanup() {
	for dir in "${TEMP_DIRS[@]}"; do
		rm -rf "${dir}"
	done
}

trap cleanup EXIT

abort_no_temp_dirs() {
	printf 'FATAL: mktemp -d is unavailable: %s\n' "$1" >&2
	printf 'Tests export HOME to a temp dir; without one HOME is empty and ~-relative\n' >&2
	printf 'writes land inside the repo. Re-run from a terminal outside the sandbox.\n' >&2
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

add_temp_dir() {
	local dir
	if ! dir="$(mktemp -d 2>&1)" || [[ -z ${dir} ]]; then
		abort_no_temp_dirs "${dir:-no output}"
		# exit would only leave this command substitution; the signal reaches the suite.
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

test_link_runcoms_backups_existing_files() {
	local tmp_home
	tmp_home="$(add_temp_dir)"
	export HOME="${tmp_home}"
	BACKUP_DIR="${HOME}/.dotfiles-backup"
	mkdir -p "${BACKUP_DIR}"
	printf 'original content\n' >"${HOME}/.zprofile"

	link_runcoms >/dev/null 2>&1

	local target
	if [[ ! -L "${HOME}/.zprofile" ]]; then
		return 1
	fi
	target="$(readlink "${HOME}/.zprofile")"
	if [[ ${target} != "${REPO_ROOT}/zsh/runcoms/zprofile" ]]; then
		return 1
	fi
	if [[ ! -f "${BACKUP_DIR}/zprofile" ]]; then
		return 1
	fi
	# shellcheck disable=SC2312
	if [[ "$(cat "${BACKUP_DIR}/zprofile")" != "original content" ]]; then
		return 1
	fi

	return 0
}

test_setup_node_uses_mise_and_installs_missing_globals() {
	local stub_root stub_bin log_file
	stub_root="$(add_temp_dir)"
	stub_bin="${stub_root}/bin"
	log_file="${stub_root}/mise.log"
	mkdir -p "${stub_bin}"

	cat <<'EOF' >"${stub_bin}/mise"
#!/usr/bin/env bash
set -euo pipefail
log_file="${MISE_LOG:?}"
printf '%s\n' "$*" >> "${log_file}"

if [[ "$1" == "use" ]]; then
  exit 0
fi

if [[ "$1" == "exec" && "$2" == "--" && "$3" == "npm" && "$4" == "list" ]]; then
  exit 1
fi

if [[ "$1" == "exec" && "$2" == "--" && "$3" == "npm" && "$4" == "install" ]]; then
  exit 0
fi

exit 0
EOF
	chmod +x "${stub_bin}/mise"

	local original_path="${PATH}"
	local original_node_version="${DOTFILES_NODE_VERSION-}"
	PATH="${stub_bin}:${PATH}"
	export MISE_LOG="${log_file}"
	export DOTFILES_NODE_VERSION="22"

	set +e
	bash "${REPO_ROOT}/scripts/setup-node.sh" >/dev/null 2>&1
	local status=$?
	set -e

	PATH="${original_path}"
	unset MISE_LOG
	if [[ -n ${original_node_version} ]]; then
		export DOTFILES_NODE_VERSION="${original_node_version}"
	else
		unset DOTFILES_NODE_VERSION
	fi

	if [[ ${status} -ne 0 ]]; then
		return 1
	fi

	if ! grep -Fxq "use -g node@22" "${log_file}"; then
		return 1
	fi

	if ! grep -Fq "exec -- npm list -g --depth=0 @anthropic-ai/claude-code" "${log_file}"; then
		return 1
	fi

	if ! grep -Fq "exec -- npm install -g @anthropic-ai/claude-code" "${log_file}"; then
		return 1
	fi

	return 0
}

test_doctor_passes_with_custom_manifest_and_stubbed_commands() {
	local tmp_dir stub_bin manifest_file
	tmp_dir="$(add_temp_dir)"
	stub_bin="${tmp_dir}/bin"
	manifest_file="${tmp_dir}/target-state.sh"
	mkdir -p "${stub_bin}"

	cat <<'EOF' >"${stub_bin}/stubcmd"
#!/usr/bin/env bash
exit 0
EOF
	chmod +x "${stub_bin}/stubcmd"

	cat <<'EOF' >"${manifest_file}"
#!/usr/bin/env bash
REQUIRED_COMMANDS=(stubcmd)
REQUIRED_BREW_FORMULAE=()
REQUIRED_BREW_CASKS=()
REQUIRED_MISE_TOOLS=()
NODE_GLOBAL_PACKAGES_FILE=""
EOF

	local original_path="${PATH}"
	PATH="${stub_bin}:${PATH}"

	set +e
	bash "${REPO_ROOT}/scripts/doctor.sh" --manifest "${manifest_file}" >/dev/null 2>&1
	local status=$?
	set -e

	PATH="${original_path}"

	[[ ${status} -eq 0 ]]
}

test_doctor_fails_for_missing_required_command() {
	local tmp_dir manifest_file
	tmp_dir="$(add_temp_dir)"
	manifest_file="${tmp_dir}/target-state.sh"

	cat <<'EOF' >"${manifest_file}"
#!/usr/bin/env bash
REQUIRED_COMMANDS=(definitely_missing_command_for_test)
REQUIRED_BREW_FORMULAE=()
REQUIRED_BREW_CASKS=()
REQUIRED_MISE_TOOLS=()
NODE_GLOBAL_PACKAGES_FILE=""
EOF

	set +e
	bash "${REPO_ROOT}/scripts/doctor.sh" --manifest "${manifest_file}" >/dev/null 2>&1
	local status=$?
	set -e

	[[ ${status} -ne 0 ]]
}

test_doctor_accepts_plain_mise_current_output() {
	local tmp_dir stub_bin manifest_file
	tmp_dir="$(add_temp_dir)"
	stub_bin="${tmp_dir}/bin"
	manifest_file="${tmp_dir}/target-state.sh"
	mkdir -p "${stub_bin}"

	cat <<'EOF' >"${stub_bin}/mise"
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1-}" == "current" && "${2-}" == "node" ]]; then
  echo "20.20.0"
  exit 0
fi
if [[ "${1-}" == "exec" ]]; then
  exit 0
fi
exit 0
EOF
	chmod +x "${stub_bin}/mise"

	cat <<'EOF' >"${manifest_file}"
#!/usr/bin/env bash
REQUIRED_COMMANDS=(mise)
REQUIRED_BREW_FORMULAE=()
REQUIRED_BREW_CASKS=()
REQUIRED_MISE_TOOLS=(node@20)
NODE_GLOBAL_PACKAGES_FILE=""
EOF

	local original_path="${PATH}"
	PATH="${stub_bin}:${PATH}"

	set +e
	bash "${REPO_ROOT}/scripts/doctor.sh" --manifest "${manifest_file}" >/dev/null 2>&1
	local status=$?
	set -e

	PATH="${original_path}"

	[[ ${status} -eq 0 ]]
}

test_link_claude_skills_links_each_skill() {
	local tmp_home
	tmp_home="$(add_temp_dir)"
	export HOME="${tmp_home}"

	link_claude_skills >/dev/null 2>&1

	local target="${HOME}/.claude/skills/miro-storymap-extract"
	if [[ ! -L ${target} ]]; then
		return 1
	fi
	# shellcheck disable=SC2312
	if [[ "$(readlink "${target}")" != "${REPO_ROOT}/claude/skills/miro-storymap-extract" ]]; then
		return 1
	fi

	return 0
}

test_link_claude_skills_skips_existing_entry() {
	local tmp_home
	tmp_home="$(add_temp_dir)"
	export HOME="${tmp_home}"
	mkdir -p "${HOME}/.claude/skills/miro-storymap-extract"
	printf 'sentinel\n' >"${HOME}/.claude/skills/miro-storymap-extract/KEEP"

	link_claude_skills >/dev/null 2>&1

	if [[ -L "${HOME}/.claude/skills/miro-storymap-extract" ]]; then
		return 1
	fi
	# shellcheck disable=SC2312
	if [[ "$(ls -A "${HOME}/.claude/skills/miro-storymap-extract")" != "KEEP" ]]; then
		return 1
	fi

	return 0
}

test_profile_scoped_links_are_included_for_that_profile() {
	local saved
	saved="$(declare -p SELECTED_PROFILES)"
	# Bash is dynamically scoped, so this local is visible to selected_config_links.
	# shellcheck disable=SC2034
	local -a CONFIG_LINKS_work=("fixture/scoped.conf:.config/scoped.conf")
	SELECTED_PROFILES=(always work)

	if ! selected_config_links | grep -qx "fixture/scoped.conf:.config/scoped.conf"; then
		eval "${saved}"
		return 1
	fi

	eval "${saved}"
	return 0
}

test_other_profiles_exclude_scoped_links() {
	local saved
	saved="$(declare -p SELECTED_PROFILES)"
	# shellcheck disable=SC2034
	local -a CONFIG_LINKS_work=("fixture/scoped.conf:.config/scoped.conf")
	SELECTED_PROFILES=(always home)

	if selected_config_links | grep -qx "fixture/scoped.conf:.config/scoped.conf"; then
		eval "${saved}"
		return 1
	fi

	# the identity-shared links must still be present on a home machine
	if ! selected_config_links | grep -qx "claude/CLAUDE.md:.claude/CLAUDE.md"; then
		eval "${saved}"
		return 1
	fi

	eval "${saved}"
	return 0
}

test_absent_overlay_leaves_config_links_clean() {
	local tmp_root saved_root saved_profiles output err status
	tmp_root="$(add_temp_dir)"
	saved_root="${DOTFILES_ROOT}"
	saved_profiles="$(declare -p SELECTED_PROFILES)"

	DOTFILES_ROOT="${tmp_root}"
	SELECTED_PROFILES=(always)

	err="${tmp_root}/stderr"
	status=0
	output="$(selected_config_links 2>"${err}")" || status=$?

	DOTFILES_ROOT="${saved_root}"
	eval "${saved_profiles}"

	if ((status != 0)); then
		return 1
	fi
	# Stderr is load-bearing: an unguarded source of the absent seam still returns 0.
	if [[ -s ${err} ]]; then
		return 1
	fi
	if ! printf '%s\n' "${output}" | grep -qx "claude/CLAUDE.md:.claude/CLAUDE.md"; then
		return 1
	fi
	if printf '%s\n' "${output}" | grep -q '^local/'; then
		return 1
	fi

	return 0
}

test_overlay_contributes_its_links_when_present() {
	local tmp_root saved_root saved_profiles found
	tmp_root="$(add_temp_dir)"
	saved_root="${DOTFILES_ROOT}"
	saved_profiles="$(declare -p SELECTED_PROFILES)"

	mkdir -p "${tmp_root}/local"
	cat >"${tmp_root}/local/links.sh" <<-'OVERLAY'
		CONFIG_LINKS_LOCAL=(
			"local/overlay-only.md:.config/overlay-only.md"
		)
	OVERLAY

	DOTFILES_ROOT="${tmp_root}"
	SELECTED_PROFILES=(always)

	found=1
	if selected_config_links | grep -qx "local/overlay-only.md:.config/overlay-only.md"; then
		found=0
	fi

	DOTFILES_ROOT="${saved_root}"
	eval "${saved_profiles}"
	unset CONFIG_LINKS_LOCAL 2>/dev/null || true
	return "${found}"
}

test_refuses_to_run_from_worktree_checkout() {
	local saved="${DOTFILES_ROOT}"
	DOTFILES_ROOT="/Users/someone/projects/dotfiles/.claude/worktrees/abc123"

	if ensure_not_worktree_checkout 2>/dev/null; then
		DOTFILES_ROOT="${saved}"
		return 1
	fi

	DOTFILES_ROOT="${saved}"
	return 0
}

test_allows_run_from_main_checkout() {
	local saved="${DOTFILES_ROOT}"
	DOTFILES_ROOT="/Users/someone/projects/dotfiles"

	if ! ensure_not_worktree_checkout 2>/dev/null; then
		DOTFILES_ROOT="${saved}"
		return 1
	fi

	DOTFILES_ROOT="${saved}"
	return 0
}

test_link_config_files_links_style_md() {
	local tmp_home
	tmp_home="$(add_temp_dir)"
	export HOME="${tmp_home}"
	BACKUP_DIR="${HOME}/.dotfiles-backup"

	link_config_files >/dev/null 2>&1

	local target="${HOME}/.claude/STYLE.md"
	if [[ ! -L ${target} ]]; then
		printf '  STYLE.md is not linked into ~/.claude\n' >&2
		return 1
	fi
	if [[ "$(readlink "${target}")" != "${DOTFILES_ROOT}/claude/STYLE.md" ]]; then
		printf '  STYLE.md links to %s\n' "$(readlink "${target}")" >&2
		return 1
	fi

	return 0
}

test_link_config_files_targets_all_resolve() {
	local tmp_home
	tmp_home="$(add_temp_dir)"
	export HOME="${tmp_home}"
	BACKUP_DIR="${HOME}/.dotfiles-backup"

	link_config_files >/dev/null 2>&1

	local link_spec target_rel target
	for link_spec in "${CONFIG_LINKS[@]}"; do
		target_rel="${link_spec#*:}"
		target="${HOME}/${target_rel}"

		# -e follows the link, so a dangling symlink fails here
		if [[ ! -e ${target} ]]; then
			printf '  unresolved config link: %s\n' "${target_rel}" >&2
			return 1
		fi
		if [[ ! -L ${target} ]]; then
			printf '  not a symlink: %s\n' "${target_rel}" >&2
			return 1
		fi
	done

	return 0
}

test_suite_aborts_when_mktemp_unavailable() {
	if [[ -n ${DOTFILES_TESTS_CHILD-} ]]; then
		return 0
	fi

	local stub_bin
	stub_bin="$(add_temp_dir)/bin"
	mkdir -p "${stub_bin}"
	cat <<'EOF' >"${stub_bin}/mktemp"
#!/usr/bin/env bash
echo "mktemp: mkdtemp failed on /var/folders/stub: Operation not permitted" >&2
exit 1
EOF
	chmod +x "${stub_bin}/mktemp"

	set +e
	local output
	output="$(DOTFILES_TESTS_CHILD=1 PATH="${stub_bin}:${PATH}" bash "${REPO_ROOT}/tests/install-tests.sh" 2>&1)"
	local status=$?
	set -e

	if [[ ${status} -eq 0 ]]; then
		return 1
	fi

	# Refuse to run at all, rather than half-running with an empty HOME.
	if [[ ${output} == *"PASS:"* ]]; then
		return 1
	fi

	if [[ ${output} != *"mktemp -d"* ]]; then
		return 1
	fi

	return 0
}

run_test "suite aborts when mktemp -d is unavailable" test_suite_aborts_when_mktemp_unavailable
run_test "link_runcoms backs up existing runcoms" test_link_runcoms_backups_existing_files
run_test "setup-node uses mise and installs missing npm globals" test_setup_node_uses_mise_and_installs_missing_globals
run_test "doctor succeeds with a valid custom manifest" test_doctor_passes_with_custom_manifest_and_stubbed_commands
run_test "doctor fails when required commands are missing" test_doctor_fails_for_missing_required_command
run_test "doctor handles plain mise current output" test_doctor_accepts_plain_mise_current_output
run_test "link_claude_skills links each skill dir" test_link_claude_skills_links_each_skill
run_test "link_claude_skills skips existing entries" test_link_claude_skills_skips_existing_entry
run_test "profile-scoped links are included for that profile" test_profile_scoped_links_are_included_for_that_profile
run_test "other profiles exclude scoped links" test_other_profiles_exclude_scoped_links
run_test "absent overlay leaves config links clean" test_absent_overlay_leaves_config_links_clean
run_test "overlay contributes its links when present" test_overlay_contributes_its_links_when_present
run_test "install refuses to run from a worktree checkout" test_refuses_to_run_from_worktree_checkout
run_test "install allows the main checkout" test_allows_run_from_main_checkout
run_test "link_config_files links STYLE.md into ~/.claude" test_link_config_files_links_style_md
run_test "link_config_files leaves every target resolving" test_link_config_files_targets_all_resolve

printf '\nTests run: %d, Failures: %d\n' "${TEST_COUNT}" "${FAIL_COUNT}"

if [[ ${FAIL_COUNT} -gt 0 ]]; then
	exit 1
fi
