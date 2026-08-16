#!/usr/bin/env bash
# shellcheck disable=SC2034  # Variables are consumed by scripts/doctor.sh via source

# Core commands expected to be available in PATH.
REQUIRED_COMMANDS=(
	git
	brew
	direnv
	mise
	starship
	rg
	claude
)

# Baseline Homebrew packages expected on every machine.
REQUIRED_BREW_FORMULAE=(
	git
	direnv
	mise
	starship
	ripgrep
)

# No casks required by this repo. Kept as an empty array — scripts/doctor.sh checks its length
# under `set -u`, so the array must exist even when there is nothing in it.
REQUIRED_BREW_CASKS=()

# Required globally active mise tool versions.
NODE_VERSION="22"
REQUIRED_MISE_TOOLS=(
	"node@${NODE_VERSION}"
)

# File listing required npm globals.
NODE_GLOBAL_PACKAGES_FILE="node/global-packages.txt"
