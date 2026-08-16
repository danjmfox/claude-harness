#!/usr/bin/env bash
# shellcheck disable=SC2034  # Variables are consumed by scripts/doctor.sh via source

# Target state for Docker / Linux CI validation.
# This repo has no brew step. install.sh only does symlinks and node globals.

REQUIRED_COMMANDS=(
	git
	zsh
	mise
)

REQUIRED_BREW_FORMULAE=()
REQUIRED_BREW_CASKS=()

NODE_VERSION="22"
REQUIRED_MISE_TOOLS=(
	"node@${NODE_VERSION}"
)

NODE_GLOBAL_PACKAGES_FILE="node/global-packages.txt"

REQUIRED_SYMLINKS=(
	"${HOME}/.zshrc:${REPO_ROOT}/zsh/runcoms/zshrc"
	"${HOME}/.zshenv:${REPO_ROOT}/zsh/runcoms/zshenv"
	"${HOME}/.zprofile:${REPO_ROOT}/zsh/runcoms/zprofile"
	"${HOME}/.zlogin:${REPO_ROOT}/zsh/runcoms/zlogin"
	"${HOME}/.config/starship.toml:${REPO_ROOT}/config/starship/starship.toml"
	"${HOME}/.config/direnv/direnv.toml:${REPO_ROOT}/config/direnv/direnv.toml"
	"${HOME}/.claude/CLAUDE.md:${REPO_ROOT}/claude/CLAUDE.md"
	"${HOME}/.claude/PRINCIPLES.md:${REPO_ROOT}/claude/PRINCIPLES.md"
	"${HOME}/.claude/stack.md:${REPO_ROOT}/claude/stack.md"
)
