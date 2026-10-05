# How to turn on the RED gate in a project

Type: How-To. Goal: make Claude Code refuse edits to your source until a test has failed, and refuse to finish until the tests pass again.

Background reading is in the decision record `docs/decisions/DR--20261005--process--red-gate-hook.md`. The field-by-field specification is in `docs/reference/hooks.md`.

## Before you start

- Run `./install.sh` so `~/.claude/hooks/red-gate.sh` exists.

## Steps

1. Register the hook by following `docs/howto/register-the-hooks.md`, keeping the four `red-gate.sh` entries.
2. Create `.claude/red-gate.json` in the project you want gated:

   ```json
   {
     "test_command": "npm test|vitest",
     "gated": ["src/"]
   }
   ```

   `test_command` is a regular expression matched against each Bash command. `gated` lists path prefixes relative to the project root.

3. Add `.claude/red-gate-state.json` and `.claude/red-gate-bypass.jsonl` to the project's `.gitignore`.
4. Start a session in the project and ask Claude to edit a file under `src/`. The edit is refused with WHAT, WHY and NEXT.
5. Run the test command so a test fails. The hook records `RED`, and the next edit under `src/` is allowed.
6. Run the test command so it passes. The hook records `GREEN`, and Claude can finish.

## Bypass the gate

Set the reason in the environment before you start the session:

```bash
RED_GATE_BYPASS="spike, no test yet" claude
```

While it is set, gated edits and `Stop` are allowed. Each use appends a line to `.claude/red-gate-bypass.jsonl`. Read that file to see where the gate does not fit how you work:

```bash
cat .claude/red-gate-bypass.jsonl
```

## Check that it works

Confirm the hook records a failing run. After step 5, the state file contains `RED`:

```bash
cat .claude/red-gate-state.json
```

If the file is missing after a failing test run, the harness did not send `PostToolUseFailure` for that command. Check the registration in step 1.

> Aside: the gate checks that a test failed, not that the test is meaningful. A trivial failing test opens it.
