# claude-harness — Project Context

## Layout

- `claude/` — the harness: standing orders (`CLAUDE.md`, `STYLE.md`, `PRINCIPLES.md`,
  `ENGINEERING-DEFAULTS.md`, `stack.md`), `hooks/`, and `skills/`
- `install.sh` — symlinks all of it into `~/.claude/`, plus zsh runcoms
- `tests/` — eight bash suites; they source `install.sh` directly and call individual functions
- `local/` — optional private overlay, gitignored, absent by default. See the README

## Install script conventions

- Model for new link functions: `link_config_files()` — loop, skip-if-exists (`-e` or `-L`), `ln -s`
- Call new functions from `main()` in declaration order
- `./install.sh` only symlinks and sets up Node globals; safe to re-run
- Hooks are explicit `CONFIG_LINKS` entries, not a glob — a new `claude/hooks/*.sh` stays inert
  until added, however often `install.sh` runs
- `CONFIG_LINKS` is identity-shared: the same on every machine, because it is about the user.
  Anything environment-bound belongs in a `CONFIG_LINKS_<profile>` array, and anything private
  belongs in the overlay's `local/links.sh`. This repo names none of the overlay's files, and
  declares no `CONFIG_LINKS_<profile>` array of its own

## Test harness pattern

- Override `HOME` with `$(add_temp_dir)` to isolate filesystem effects
- Also override `DOTFILES_ROOT`-relative vars if the function uses them
- `run_test "description" test_fn_name` — returns 0/1 from the function
- Hook suites (`tests/*-guard-tests.sh`) build a fixture payload with `python3 -c`, pipe it to the
  hook, then assert exit 2 vs 0 or parse the stdout JSON. Never pass a fixture on a command line —
  a text-matching guard blocks a command that merely *mentions* a blocked pattern
- **A test that passes on arrival has not been verified.** Break the thing it covers, watch it go
  red, restore. Two tests in `tests/zshrc-tests.sh` exist because the obvious version of each
  passed with the implementation deleted

## Skills install

- `link_claude_skills` symlinks each dir under `claude/skills/` into `~/.claude/skills/`, skipping
  any entry that already exists — so a skill manager's own directories there stay untouched
- It only creates *missing* symlinks. Stale skill links must be deleted first, or a re-run silently
  leaves them in place
- `~/.claude/settings.json` is a **real file, not a symlink from here** — `install.sh` does not
  reference it. Edit it in place. Standing orders are the opposite case: `~/.claude/CLAUDE.md` *is*
  a symlink to `claude/CLAUDE.md`, so edit the git-tracked copy, never the live path

## Environment constraints are not universal

Sandbox denials — blocked writes, blocked network, a denied `mktemp -d` — vary by machine. This file
previously carried one machine's as if they were properties of the repo, and six of them were
falsified on a second machine. If a command fails in a way that looks like a permission denial,
probe it rather than looking it up. Machine-specific findings belong in your overlay.

## Working on this repo

- **Never run `install.sh` from a worktree copy.** `DOTFILES_ROOT` resolves from the script's own
  location, so a worktree run repoints every symlink into that worktree — where edits on the main
  checkout then look inert. The script self-guards against this, but the reason is worth knowing
- **Run trunk from the worktree holding the work, not the main checkout.** On main it either does
  nothing, because the files it would format are elsewhere, or it edits main's copy and aborts the
  next merge with `local changes would be overwritten`
- **Commit the `trunk fmt` result — the pre-push hook judges commits, not the working tree.** A
  green `trunk check` and a red push is not a contradiction: the fix was sitting uncommitted. The
  reliable order is fmt, commit, push
- **`trunk fmt` is not a proxy for `trunk check` — most lint rules are not autofixable.** Lint
  separately with the pinned binary. The linter configs live in `.trunk/configs/` as **dotfiles**,
  so plain `ls` shows nothing and reads as "no config" — use `ls -a`. Common offenders in prose:
  `MD034` bare URLs (wrap in `<>`, which leaves `[text](url)` links alone) and `MD037`, where an
  unescaped `*` pairs with a later `*emphasis*` to form a false span
- **`trunk.yaml` exempts the prose config docs** from `prettier`/`markdownlint` — the root
  `CLAUDE.md`, `claude/CLAUDE.md`, `claude/ENGINEERING-DEFAULTS.md`, `claude/skills/**`. `trunk fmt`
  on one of these reports `Checked 0 files`, which is success, not failure
- **Trunk's pinned tools run directly, bypassing the daemon:**
  `~/.cache/trunk/tools/prettier/<version>-*/node_modules/.bin/prettier -w <file>`, and likewise for
  `shellcheck`. `shfmt` has version directories but no binary inside them, so shell *formatting* is
  verifiable only where trunk itself runs
- **Never amend a commit whose hash you have already reported.** Whenever merges happen out of sight
  the commit may already be on `main`, and amending produces a conflicting sibling rather than an
  update: same base, same lines, two independent edits. Add a follow-up commit instead
- **Do not verify a symlinked file's live state by grepping for a phrase.** The check has to
  discriminate new content from old, and a phrase from the new wording is often already present in
  the old file. `git diff <ref> -- <path>` gives an insert/delete count that cannot be satisfied
  without the change
