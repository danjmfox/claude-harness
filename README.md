# claude-harness

A working Claude Code harness: standing orders, guard hooks, and skills, plus the zsh setup that
carries them.

**Type:** this README is a How-To. The reasoning behind the design lives in the files themselves —
the standing orders in particular explain why each rule exists.

## What you get

| Path                             | What it is                                                                                   |
| -------------------------------- | -------------------------------------------------------------------------------------------- |
| `claude/CLAUDE.md`               | Standing orders — role, workflow, operational constraints, communication rules               |
| `claude/STYLE.md`                | Turn shape: fixed heading slots, and when structure is required at all                       |
| `claude/PRINCIPLES.md`           | Five engineering virtues, each framed as a transition away from something                    |
| `claude/ENGINEERING-DEFAULTS.md` | Git discipline, verification, quality gates — indexed by _event_, not by topic               |
| `claude/hooks/`                  | Four `PreToolUse` guards: git discipline, test integrity, agent dispatch, monitoring         |
| `claude/skills/`                 | Seventeen skills — `/red`, `/green`, `/refactor`, `/review`, `/ship`, `/survey`, `/watch`, … |
| `zsh/runcoms/`                   | zsh startup files symlinked into `$HOME`, plus the plugin submodules they load               |
| `install.sh`                     | Symlinks all of the above into `~/.claude/` and `$HOME`                                      |
| `tests/`                         | Eight bash suites covering the installer, the hooks, the skills, and zshrc                   |

## Quick start

```bash
git clone <this-repo> ~/projects/claude-harness
cd ~/projects/claude-harness
git submodule update --init --recursive zsh/plugins
./install.sh
```

`install.sh` only symlinks files and sets up Node globals via `mise` — it has no package manager
step of its own. It is idempotent, and backs up anything it replaces into `~/.dotfiles-backup`.
`./uninstall.sh` restores those backups.

Verify a machine against the target-state manifest at any time:

```bash
./scripts/doctor.sh
```

## Taking the parts you want

Nothing here is all-or-nothing. The standing orders are the densest single artifact and read
independently of the install machinery — `claude/CLAUDE.md` and `claude/STYLE.md` are useful copied
straight into your own `~/.claude/`. The hooks in `claude/hooks/` are self-contained bash and need
only a `settings.json` entry. Skills are directories; symlink or copy the ones you want.

## The `local/` overlay

Anything personal, employer-specific, or machine-specific is expected to live outside this repo, in
a private checkout mounted at `local/`:

```bash
ln -s ~/projects/my-private-dotfiles local
```

Two seams pick it up, and **both skip cleanly when `local/` is absent** — that absent path is the
default and is covered by acceptance tests, so it is a supported configuration rather than a
degraded one:

1. **`local/links.sh`** — declares `CONFIG_LINKS_LOCAL`, and may append to any
   `CONFIG_LINKS_<profile>` array. Sourced by `selected_config_links()` before profiles are
   collected. See [`local.example/links.sh`](local.example/links.sh).
2. **`local/zshrc.local`** — sourced last by `zsh/runcoms/zshrc`, so it can override anything above.

This repo names none of the overlay's files. It knows overlays exist and nothing about their
contents.

### Why a symlink rather than a nested clone

`git clean -xdf` removes ignored paths. A checkout nested inside `local/` would be deleted along
with any uncommitted work in it; a symlink costs one `ln -s` to restore.

### A `local/work/` convention

If some of your configuration belongs to an employer rather than to you, keeping it under
`local/work/` makes the boundary a directory listing rather than a file-by-file review — which
matters on the day you need to hand it back or drop it. This is a filing convention described here
and nowhere else: `install.sh` knows only about the overlay root, so nothing forces this shape on
you if your situation differs.

## `--profile`

`install.sh --profile <work|home|personaldev|all>` selects which `CONFIG_LINKS_<profile>` array
gets applied, on top of the identity-shared base links. This repo declares no profile-scoped links
of its own — the mechanism exists purely for your overlay to use. `--profile work` with no overlay
present is a no-op beyond the base links.

## Environment constraints are not universal

`claude/CLAUDE.md` deliberately carries a _method_ for handling sandbox and platform denials rather
than a table of facts about them. An earlier version listed six constraints as properties of Claude
Code; every one turned out to be a property of one particular managed laptop, and false elsewhere.

The practical version: probe before trusting a recorded constraint, re-test after a version bump,
and keep machine-specific findings in your overlay. A constraint written down as universal is how a
capability that works gets believed unavailable.

## Zsh setup

- Runcoms (`zshrc`, `zprofile`, `zshenv`, `zlogin`) live in `zsh/runcoms/` and are symlinked by
  `install.sh`. Edit the tracked files, not `~/.zshrc` directly.
- Plugins (autosuggestions, syntax-highlighting, history-substring-search) live as submodules under
  `zsh/plugins/` and are sourced directly from `zshrc` via `$DOTFILES`.
- `zshenv` resolves `$DOTFILES` from its own real path, so the config works regardless of where the
  repo is checked out.
- To update plugins: `git submodule update --remote zsh/plugins`, then commit the updated refs.

## Node setup

`scripts/setup-node.sh`, invoked by `install.sh`, uses `mise` to set a global Node version (`22` by
default, override with `DOTFILES_NODE_VERSION`) and installs every package listed in
`node/global-packages.txt` via `npm install -g`. Currently that list is just the Claude Code CLI
itself.

## Tests

```bash
for suite in tests/*-tests.sh; do bash "$suite"; done
```

The suites source `install.sh` directly and call individual functions, with `HOME` redirected to a
temp dir. The hook suites build a JSON payload, pipe it to the guard, and assert on the exit code —
never passing a fixture on a command line, because a text-matching guard blocks a command that
merely _mentions_ a blocked pattern.

CI runs all of them, plus a clean install with no overlay present, on every push and pull request.

## Caveats

- **macOS only**, for the runcoms and the `defaults`-based hooks. The bash tooling itself is
  portable — that's what CI exercises on Linux.
- **Opinionated by construction.** The standing orders encode one person's practice, including a
  specific agile/TDD methodology. They are meant to be edited, not adopted wholesale.
- **The skills assume Claude Code.** Some also assume `gh` or `glab`.
- **No package manager step.** This repo does not install software for you — bring your own
  Homebrew, apt, or whatever your machine uses. It only symlinks configuration.
