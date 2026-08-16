#!/usr/bin/env bash
set -euo pipefail

# bootstrap.sh — pre-install setup for a bare macOS machine.
# Run once before install.sh. Safe to re-run.

install_xcode_cli_tools() {
	if xcode-select -p >/dev/null 2>&1; then
		printf 'Xcode CLI tools already installed.\n'
		return
	fi

	printf 'Installing Xcode CLI tools...\n'
	xcode-select --install

	printf 'Waiting for Xcode CLI tools installation to complete...\n'
	local elapsed=0 timeout=300
	until xcode-select -p >/dev/null 2>&1; do
		sleep 5
		elapsed=$((elapsed + 5))
		if ((elapsed >= timeout)); then
			printf 'Timed out waiting for Xcode CLI tools. Re-run bootstrap.sh after installation completes.\n' >&2
			exit 1
		fi
	done
	printf 'Xcode CLI tools installed.\n'
}

ensure_zsh_login_shell() {
	local desired
	desired="$(command -v zsh || true)"

	if [[ -z ${desired} ]]; then
		printf 'zsh not found. Install zsh, then run bootstrap.sh again.\n' >&2
		exit 1
	fi

	if [[ ${SHELL-} == "${desired}" ]]; then
		printf 'Login shell is already zsh.\n'
		return
	fi

	if ! grep -qxF "${desired}" /etc/shells; then
		printf 'Adding %s to /etc/shells (requires sudo)...\n' "${desired}"
		sudo sh -c "echo '${desired}' >> /etc/shells"
	fi

	printf 'Changing login shell to zsh (requires sudo)...\n'
	chsh -s "${desired}" "${USER}"
	printf 'Login shell changed to zsh. Restart your session, then rerun bootstrap.sh or run install.sh.\n'
}

main() {
	install_xcode_cli_tools
	ensure_zsh_login_shell

	printf '\nBootstrap complete. Run: ./install.sh --profile <work|home|personaldev|all>\n'
}

if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
	main "$@"
fi
