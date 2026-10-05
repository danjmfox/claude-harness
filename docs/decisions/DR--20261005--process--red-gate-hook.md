---
id: DR--20261005--process--red-gate-hook
status: accepted
dateCreated: 2026-10-05
domain: process
changelog:
  - date: 2026-10-05
    version: 0.1.0
    note: Initial draft, decided and applied same session; Stop gate added same day
---

# RED gate hook: block gated edits until a recorded test run has failed

## Context

The `buildy` light path (`red` → `green` → `refactor`) states "one test at a time" in prose only.
Nothing stops an edit to production code before a failing test exists. nWave's DES enforces this
with hooks that read evidence (exit status, files, git state) rather than the model's claims. This
repo has no equivalent for projects without nWave.

## Options Considered

### Option 1: Prose rule only (status quo)

Zero cost, but the model can skip RED without anyone seeing it.

### Option 2: Adopt DES for non-nWave projects

DES is wired to nWave's step and roadmap model. Reusing it would pull that machinery into projects
that never installed it.

### Option 3: A small hook pair with opt-in config

`claude/hooks/red-gate.sh` handles `PreToolUse` on `Edit`/`Write`/`MultiEdit` and
`PostToolUse`/`PostToolUseFailure` on `Bash`, and `Stop`. A project opts in with `.claude/red-gate.json`
(`test_command` regex, `gated` path prefixes). A failing run of the test command records `RED` in
`.claude/red-gate-state.json`; a passing run records `GREEN` and clears a `dirty` flag. A gated edit is allowed only in
`RED`, and each allowed edit sets `dirty`. `Stop` is blocked while `dirty` is set. Refusals use WHAT / WHY / NEXT.

## Decision

Option 3. Four properties are deliberate:

- **Evidence, not claims.** RED comes from the harness reporting a non-zero exit
  (`PostToolUseFailure`), never from a statement by the model. The hook blocks `Edit`/`Write` to the
  state file and the bypass log.
- **Visible bypass.** A human sets `RED_GATE_BYPASS="<reason>"` in the session environment. Each
  gated edit allowed that way appends a line to `.claude/red-gate-bypass.jsonl`. The bypass log
  shows where the gate does not fit how the work is actually done.
- **Unverified edits cannot be finished.** `Stop` is blocked while gated edits have no passing run
  after them, so a green run that predates the last edit does not count. A turn with no gated edit
  is never blocked. A repeated `Stop` (`stop_hook_active`) is allowed so the agent cannot loop, and
  is logged as `unresolved-at-stop`. `RED_GATE_BYPASS` also allows `Stop` and logs the reason.
- **Deterministic only.** The gate checks a script-checkable fact. It cannot tell a meaningful
  failing test from a trivial one.

## Exceptions

- **Not wired by `install.sh` alone.** `install.sh` links the script. Registering the hook in
  `~/.claude/settings.json` is a manual step, because that file is not managed from this repo.
- **Bash can still write the state file.** The gate blocks `Edit`/`Write` only. A shell redirect
  into `.claude/` is not caught.
- **Goodhart.** A trivial failing test opens the gate. Mutation testing is the usual fix and is out
  of scope here.
- **Unverified harness assumption.** The hook assumes a non-zero Bash exit fires
  `PostToolUseFailure`. The tests use that event name as a fixture and do not prove the harness
  sends it.
- **`buildy` deviation.** Built by direct execution, not through `buildy`: this repo has `.nwave/`
  (so the light path is unavailable) and is Bash rather than Vitest/TS. Behaviour is pinned by
  `tests/red-gate-tests.sh`.
- **Any matching run counts as green.** A filtered run such as `vitest one.test.ts` clears `dirty`
  because it matches `test_command`. A separate `suite_command` field would close this and is not
  built.

## Registration

Add four entries to `~/.claude/settings.json`, each running `$HOME/.claude/hooks/red-gate.sh`:
`PreToolUse` with matcher `Edit|Write|MultiEdit`, `PostToolUse` and `PostToolUseFailure` with matcher
`Bash`, and `Stop`. Then add `.claude/red-gate.json` to each project that opts in.
