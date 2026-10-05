# Reference: Hooks in `claude/hooks/`

Type: Reference. Each entry uses the same fields: Event, Matcher, Effect, Why, Blocks, Config, Bypass, Test suite. `Why` states the reason recorded in the hook's header comment, the standing orders or a decision record. `Blocks: yes` means the hook can exit 2 and stop the tool call. `Blocks: no` means it only reports.

`install.sh` symlinks each script into `~/.claude/hooks/`. It does not register them. Registration is an entry in `~/.claude/settings.json`, which this repo does not manage. Every command is `$HOME/.claude/hooks/<name>.sh`.

## git-guard

- **Event**: `PreToolUse`
- **Matcher**: `Bash`
- **Effect**: Refuses `git add -A`, `--all` and `.`; squash merges through `gh pr merge` or `glab mr merge`; commits on the trunk branch; `git reset --hard` on the trunk branch; and force-pushes that rewrite the trunk ref. Each refusal names the rule on stderr.
- **Why**: The rules come from Git Discipline in `claude/ENGINEERING-DEFAULTS.md`. `git add -A` can sweep unrelated files (`.trunk/`, lint config, generated output) into a commit. A squash merge discards per-commit reasoning and orphans stacked PRs. A commit on the trunk, a hard reset or a force-push rewrites or pollutes the branch that others build on. The rules are about how the user works rather than the machine, so the hook is the same on every Mac.
- **Blocks**: yes
- **Config**: `GIT_GUARD_TRUNK_OK` is a space-separated list of repository names where committing on the trunk is allowed. Empty by default.
- **Bypass**: none.
- **Test suite**: `tests/git-guard-tests.sh`

## test-guard

- **Event**: `PostToolUse`
- **Matcher**: `Edit`
- **Effect**: When an edit to a test file lowers the count of assertions or test cases, or raises the count of skip markers, reports the change to the user and the model. The counts are textual and settle nothing on their own.
- **Why**: Enforces the Test Modification Prohibition: a failing test is never weakened, removed or relaxed to make it pass. The hook reports and does not block because whether an edit weakens a test cannot be decided from a diff. A block would either let real weakening through or stop legitimate refactors.
- **Blocks**: no
- **Config**: none.
- **Bypass**: not applicable.
- **Test suite**: `tests/test-guard-tests.sh`

## agent-guard

- **Event**: `PostToolUse`
- **Matcher**: `Agent`
- **Effect**: After a background subagent is dispatched, reports that nothing is sampling its progress. A dispatch with `run_in_background` set to false is ignored.
- **Why**: A background subagent produces no output until it finishes, so a stall, a crash and steady work look the same. The report points to the `watch` skill. It runs after the dispatch because before it there is no agent to describe, and no hook can verify that a watch is armed later.
- **Blocks**: no
- **Config**: none.
- **Bypass**: not applicable.
- **Test suite**: `tests/agent-guard-tests.sh`

## monitor-guard

- **Event**: `PreToolUse`
- **Matcher**: `Monitor`
- **Effect**: When the watch command contains a terminal condition (`break`), returns guidance on three ways that condition can be satisfied without the work having caused it. An unbounded watch gets no guidance.
- **Why**: A watch with a terminal condition can end without the work having caused the condition (already true at arming, true at an intermediate state, or silent on failure). Whether a given condition is vacuous cannot be decided from the command text, so the hook prompts a check and does not block.
- **Blocks**: no
- **Config**: none.
- **Bypass**: not applicable.
- **Test suite**: `tests/monitor-guard-tests.sh`

## red-gate

- **Events**: `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `Stop`
- **Matchers**: `Edit|Write|MultiEdit` for `PreToolUse`; `Bash` for `PostToolUse` and `PostToolUseFailure`; none for `Stop`
- **Effect**:
  - A failing run of the test command records `RED`. A passing run records `GREEN` and clears `dirty`.
  - `PreToolUse` refuses an edit to a gated path unless the recorded phase is `RED`. Each allowed edit sets `dirty`.
  - `PreToolUse` always refuses a write to `.claude/red-gate-state.json` and `.claude/red-gate-bypass.jsonl`.
  - `Stop` is refused while `dirty` is set, except when `stop_hook_active` is true, which is allowed and logged as `unresolved-at-stop`.
  - Every refusal uses the fields WHAT, WHY and NEXT on stderr.
- **Why**: The light `buildy` path stated "one test at a time" in prose only, and nothing stopped an edit before a failing test existed. The gate reads exit-status evidence from the harness instead of the model's claims, logs every bypass, and refuses to finish with unverified edits. See the decision record for the options considered.
- **Blocks**: yes
- **Config**: `.claude/red-gate.json` in the project root. Without it the hook does nothing. Fields: `test_command`, a regular expression matched against the Bash command, default `npm test|vitest`; `gated`, a list of path prefixes relative to the project root, default `["src/"]`.
- **Bypass**: the environment variable `RED_GATE_BYPASS` set to a reason. Each bypassed edit or stop appends a line to `.claude/red-gate-bypass.jsonl` with `timestamp`, `path` and `reason`.
- **Test suite**: `tests/red-gate-tests.sh`
- **Decision record**: `docs/decisions/DR--20261005--process--red-gate-hook.md`
- **How-To**: `docs/howto/use-the-red-gate.md`
