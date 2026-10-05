# Unattended loop, light path (no nWave)

Type: How-To. Status: draft, untested. Not yet linked from `SKILL.md`.

Goal: run the `buildy` light path (`red` → `green` → `refactor` → `check` → independent review) over several slices without a human present, after one approved plan.

Applies when `test -d .nwave` fails in the project root and the project has Vitest and TypeScript. If either is missing, stop: the light path has no non-JS TDD cycle.

## 1. Write the plan in plan mode

Enter plan mode and require every slice in this exact shape. The loop ticks the `Status` line, so free-form prose breaks it.

```text
# Plan: <feature-id>

## Slice 1: <name, one roadmap-sized layer>
Status: todo
Acceptance criteria (yours to vouch for; the loop never edits these):
- [ ] <observable behaviour>
First failing test: <file>: <test name>
Notes (implementation hints, not binding):
```

Keep the acceptance criteria separate from the notes. Approving a plan is cheap, and the criteria are the part only you can vouch for.

## 2. Approve the plan

Approval is the only human gate. Nothing after this step asks you anything.

## 3. Prepare an unattended run

Skip this step for a supervised run. Do all of it before an overnight run.

- Start the session in its own git worktree on a feature branch, so the loop's commits cannot touch `main`.
- Turn on the desktop app's keep-awake setting and plug the laptop in. A closed lid or idle sleep suspends the session, and a self-paced loop is not restored on resume.
- Use a permission mode and allowlist that cover the test, `check` and commit commands the cycle runs. An unanswered permission prompt stalls the loop, and the no-progress rule cannot detect that because it only fires on iterations that run.
- Check `~/.claude/token-budget.md` for the account's usage limits. The `/loop` documentation does not say what happens at a rate limit.
- Climb in stages: one supervised iteration, then a run of one or two slices while you are nearby, then overnight.
- In the morning, read the stop notification and `git log` before anything else. A stall sends no notification.

## 4. Launch the loop

Run `/loop` with no interval, with the prompt below. Replace `<feature-id>` and `<approved-plan-path>`.

```text
Run the buildy light path for feature <feature-id> from the approved plan at <approved-plan-path>.

Before anything else, each iteration:
a. If docs/feature/<feature-id>/PLAN.md does not exist, copy the approved plan there and commit it. From then on only PLAN.md counts.
b. Read docs/feature/<feature-id>/PARKED.md. If it is missing, create it with the header "session: <session id>, started <date>, iteration cap 20, time cap 6h".
c. Append "iteration <n> <ISO time>" to docs/feature/<feature-id>/LOOP.log. Keep that file untracked. Read the first and last lines to get the iteration count and elapsed time. If a cap is reached, go to Stop.

Then:
1. Take the first slice in PLAN.md with Status: todo. Skip any slice whose Status is blocked or that depends on one.
2. Run red, then green, then refactor, one test at a time. Start from the slice's named first failing test. Never write a second test before the first has failed, either on an unmet assertion or on a missing module.
3. Run check (lint, typecheck, coverage), not just the tests. A gate the project has not configured is a gap: name it in the status line, do not count it as a failure and do not add one. A configured gate must pass.
4. Dispatch an independent reviewer agent (pr-review-toolkit:code-reviewer) on the slice's diff. Never review your own work inline. Tell it to end with one line, exactly "BLOCKING: none" or "BLOCKING: <count>" followed by the items, and not to block on behaviour that belongs to a later slice.
5. The slice is done only when: its tests exit 0, every configured check gate passes, and the reviewer's last line is "BLOCKING: none". Say which commands you ran. Then set Status: done in PLAN.md in the same commit as the slice.
6. Never call AskUserQuestion. If a skill would ask, take the recommended default when the call is yours; park it when it is the human's (acceptance criteria, scope, architecture trade-off).
7. Never edit a slice's acceptance criteria or weaken, remove or relax a failing test. If a criterion seems wrong or a test cannot pass after 3 distinct attempts, set Status: blocked and add a PARKED.md entry listing the attempts.
8. If a task cannot be done as given, say so plainly in this turn. Do not narrow scope silently.
9. On a permission denial or sandbox error, set the slice blocked with the exact command and error. Do not try another route to the same effect. Never write under .claude/ or ~/.claude/.
10. Use a new commit for every change. Stage named paths only; never git add -A or git add . (a hook blocks both). Never amend a reported commit. Do not push and do not mark any PR ready.

PARKED.md entry format:
## <date> <slice> (<3-word summary>)
Status: parked | blocked
Question:
Assumed / not done:
Evidence (file:line):

Stop (send a push notification saying why, call ScheduleWakeup with stop:true, then report) when any of these holds:
- Every slice is done. Report that the work is ready for docs-review and ship.
- Every remaining slice is blocked or depends on a blocked one.
- Two consecutive iterations add no commit and no new parked item.
- The iteration cap or the time cap is reached.

Do not poll background agents; the harness notifies you. Use ScheduleWakeup only for external state such as CI, at 1200s or longer.

End each iteration with one status line: slice, done or blocked, tests green or red, parked count, iteration number.
```

## 5. Finish by hand

The loop stops at the point the `buildy` state machine calls `SHIP_READY`. Run `docs-review`, then `ship`, yourself. Pushing and marking the draft PR ready are outward-facing, so the loop does neither.
