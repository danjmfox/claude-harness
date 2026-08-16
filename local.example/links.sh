#!/usr/bin/env bash
# Example overlay link declarations.
#
# Copy this file to `local/links.sh` — where `local` is a symlink to your own
# private checkout — and `install.sh` will source it. If `local/` does not
# exist, nothing here runs and the install completes normally; that absent
# path is covered by an acceptance test, so it is a supported configuration
# rather than an accident.
#
#   ln -s ~/projects/my-private-dotfiles local
#
# A symlink, not a clone nested in the tree: `git clean -xdf` removes ignored
# paths, so a nested checkout would be deleted along with any uncommitted work,
# whereas a symlink costs one `ln -s` to restore.

# Links applied on every machine, whatever the profile.
# Each entry is "<path relative to this repo>:<path relative to $HOME>".
# shellcheck disable=SC2034 # read via indirect expansion in install.sh's selected_config_links
CONFIG_LINKS_LOCAL=(
	# "local/claude/ABOUT.md:.claude/ABOUT.md"
	# "local/claude/projects.md:.claude/projects.md"
)

# Links applied only under `--profile work`. Any CONFIG_LINKS_<profile> array
# may be appended to here; this file is sourced before profiles are collected,
# so appending works for profiles the public repo declares nothing for.
#
# CONFIG_LINKS_work+=(
# 	"local/work/npmrc:.npmrc"
# )
