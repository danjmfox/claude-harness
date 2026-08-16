---
name: watch
description: Watch long-running background work by sampling a cheap external probe, so a silent agent becomes visible progress. Use when dispatching a background subagent that will run for many minutes — an implementation agent working through a task list, a migration, a long CI run — or whenever asked to monitor, watch, or report progress on work that produces no output until it finishes.
---

Make silent background work visible by polling something outside it.

A background subagent can run 15–30 minutes with nothing on screen. Live introspection is not
available: `TaskOutput` is deprecated for agent tasks, and an agent's `.output` file is a symlink to
its full JSONL transcript, which would overflow the caller's context. Only the final result is
readable — plus whatever can be measured from outside.

For most substantive work, something external and cheap already measures it: a test count, a commit
count, an artifact appearing, a CI status, a count of migrated files. Poll that.

Claude Code specific — depends on `Monitor` and `run_in_background` agents.

## When to arm one

**Arm a watch when the sequence of intermediate states is itself evidence you cannot get from the
final report.** Not to learn that the work finished — the harness already notifies on background task
completion, so a plain "tell me when it's done" needs `run_in_background` and nothing else.

The clearest case is work that goes RED→GREEN. A completion report says "green" identically whether
the implementation was fixed or the assertions were adjusted to fit; only the curve distinguishes
them. Where the work produces no such signal, a watch offers liveness and nothing more — arm it
knowing that, or do not arm it.

Two declines, both of which held up: a read-only reviewer, whose entire output *is* its final
message, so there is no artifact to probe; and a re-arm after a monitor timed out mid-task, where the
only remaining signal was a single transition — a file set changing or not — which the completion
notification reports just as well.

## Where this sits

Plan mode settles the approach. The task list (`TaskCreate`/`TaskUpdate`/`TaskList`) tracks progress
against it and is already multi-agent — subagents claim tasks by `owner`, and `blockedBy` carries
dependencies. Neither is replaced here, and for "what is the agent up to" the task list is the better
answer: structured, typed, free.

Two things it cannot give you:

- **Independent evidence.** The task list is the agent's *self-report*. `TaskUpdate`'s own
  documentation warns against marking a task complete while tests fail — an acknowledgement that the
  report and the work come from the same source. A probe reads the artifact instead.
- **Push.** `TaskList` is a tool call, so progress only exists when you go and look. A `Monitor` runs
  shell and notifies you, which is what makes a 25-minute silence tolerable.

Use all three: plan mode for intent, the task list for what the agent *believes* it has done, a probe
for what *actually changed*. Disagreement between the last two is the finding.

## Instructions

1. **Capture a baseline** before dispatching, **using the command you will probe with.** Record the
   actual numbers; the terminal condition usually needs them as literals. Measuring the baseline a
   different way makes the two incomparable — recording 19 *tests* and then probing `it.skip`
   *markers* mixes units, because one `it.skip.each` is a single marker generating four tests. The
   baseline is also where an unsatisfiable floor shows up (question 4).
2. **Dispatch with `run_in_background: true`.**
3. **Arm a `Monitor`** that samples the probe on a loop and prints only when the derived state
   changes.
4. **Shape the terminal condition so it cannot be satisfied without the work happening.** This is
   the whole trick.

## The terminal condition is the hard part

The failure mode has a name. In model checking, a property that passes because its precondition was
never exercised is **vacuous** — the special case where the precondition is unsatisfiable is
**antecedent failure**. Beer, Ben-David, Eisner & Rodeh found roughly 20% of formulas trivially
valid in practice, and that trivial validity *always* indicated a real defect in the design, the
specification, or the environment ([FMSD 18(2):141–163,
2001](https://www.cs.toronto.edu/~chechik/courses05/csc2108/beer01.pdf)). A watch that ends on a
condition the work never had to cause is the same defect, and carries the same implication: it is
not a near miss, it means something is wrong.

Ask four questions before arming. Only the third is already covered by `Monitor`'s own tool
description; the others are where watches go blind.

1. **Could the condition already be true right now, before the work starts?** Ending on "tests are
   green" verifies nothing if the suite was green when you armed it. Require evidence of the
   *transition* — that RED was observed, that the total grew — not of the end state.
2. **Could it become true at some state the work merely passes through?** Two real failure modes:
   - **Structure arrives before substance.** An agent scaffolds its headings in the first minute, so
     "has a Sources section" is true while the document is empty. Probe *counts* — sources, tests,
     assertions, commits — never *existence*.
   - **A recurring intermediate state.** An agent working through a list of units, each ending
     RED→GREEN→COMMIT, turns the suite green once *per unit*. "Stable green" fires on unit 1 of N and
     reports success.
3. **If the work crashed right now, would the filter emit anything?** Give every probe an explicit
   "cannot run" branch. Silence and progress must not look identical. The same reasoning extends to
   gated tools: when the watched agent uses `WebSearch`, `WebFetch` or anything behind a permission
   prompt, a waiting dialog stops the work without touching the artifact, so the probe cannot see the
   block. Word the stall notice to list the states it cannot distinguish, never to claim a cause.
   Observed once, n=1, one author, 2026-08-06.
4. **Could the condition ever become true at all?** The three above ask whether the terminal is too
   *easy*. This asks whether it is *possible*, and it fails in the opposite direction: an
   unsatisfiable terminal runs the watch to timeout on finished work and reports a **stall** — the
   one signal this skill says looks identical to death. Trivial validity has a mirror in trivial
   invalidity, and only the first is famous.

   The shape that caused it: **the probe's pattern matched prose about the artifact as well as the
   artifact.** Counting `it.skip` in two test files also counted their header comments — *"EVERY
   SCENARIO IN THIS FILE IS `it.skip` ON PURPOSE"* — so the count had a floor of 1 and 5, and "zero
   skips left" could never fire. Anchor the pattern to the artifact's own syntax, `^\s*it\.skip`
   rather than `it\.skip`, so it cannot match a sentence describing the thing it counts. The same
   trap is waiting in any count of `TODO`, of a deprecated symbol, or of a migration's old API —
   each names itself in the very docs and instructions that discuss it.

   **The cheap check is to measure the baseline with the probe command itself and look at the
   floor.** If the number cannot reach its terminal value from where it starts, the watch is
   unsatisfiable and you find out in one command instead of twenty silent minutes.
   Observed once, n=1, one author, 2026-08-07.

**Sampling a target that is being edited underneath you** is the database read-skew problem: the
probe can observe a state that never coherently existed. Requiring N consecutive agreeing samples
before believing a state is the same device as Prometheus' `for` clause — pending until it holds.
When a count moves in a direction the work should make impossible, re-sample rather than conclude;
the movement is evidence about the observation, not about the work.

**A probe that writes is not a probe**, and the recipes below are the likeliest place to acquire one.
Read-skew is the probe seeing an incoherent state; this is the probe *causing* one. Running the
project's own test suite is the natural probe and also the most likely to share mutable scratch space
with the agent, which is running that same suite on its own schedule: one repo's gallery gate
regenerates into `node_modules/.cache/`, so two concurrent runs corrupt each other's fixtures and the
flake looks like the agent's bug. Prefer probes that only read — `git` plumbing, `grep`, file counts —
and reach for the suite only after checking what it writes. Where nothing but the suite will do, at
least know you have coupled the observer to the observed. Observed once, n=1, one author, 2026-08-07.

## Recipes

All three emit on change only and have a "will not run" branch. **All three also run `pnpm test` as
the probe** — read the write-side-effect caution above before copying one onto a repo whose suite
touches shared scratch space.

**Test count climbing** — terminal: green, *and* RED was observed first. The `sawred` flag is what
makes this non-vacuous; without it the watch cannot distinguish work that succeeded from a suite
that was green before it started. For a bug fix, where a regression test must also be *added*, set
`BASE` from the baseline count and additionally require `total -gt "$BASE"` before accepting green —
that combination cannot be satisfied by a fix with no test.

```bash
prev=""; sawred=0; stable=0
while true; do
  line=$(pnpm test 2>&1 | grep -E '^ *Tests +' | tail -1)
  fail=$(printf '%s' "$line" | grep -oE '[0-9]+ failed' | grep -oE '[0-9]+' || echo 0)
  pass=$(printf '%s' "$line" | grep -oE '[0-9]+ passed' | grep -oE '[0-9]+' || echo "")
  if [ -z "$pass" ]; then cur="SUITE WILL NOT RUN — likely a syntax error mid-edit"
  elif [ "$fail" -gt 0 ]; then cur="RED $fail failing, $pass passing"; sawred=1
  elif [ "$sawred" -eq 0 ]; then cur="green but RED never seen — inconclusive, not success"
  else cur="GREEN — 0 failing, $pass passing"; fi
  [ "$cur" != "$prev" ] && { echo "$cur"; prev="$cur"; }
  case "$cur" in
    GREEN*) stable=$((stable+1))
            [ "$stable" -ge 2 ] && { echo "done — RED preceded GREEN"; break; } ;;
    *) stable=0 ;;
  esac
  sleep 45
done
```

**An agent that commits once per unit of work** — the test count is the progress signal but a
*terrible* terminal condition, because green recurs per unit. Use commit count for the terminal
instead: it is monotonic and increments once per completed unit, so it cannot recur.

Before arming, get the planned unit count from wherever the work is enumerated — a roadmap file, a
task list, a migration manifest — and set `STEPS` as a literal. Reading it once up front beats
probing it, because a probe on the same file the agent is writing is subject to read skew.

```bash
prev=""; stable=0; BASE=$(git rev-list --count HEAD); STEPS=12
while true; do
  head_n=$(git rev-list --count HEAD 2>/dev/null || echo "")
  line=$(pnpm test 2>&1 | grep -E '^ *Tests +' | tail -1)
  pass=$(printf '%s' "$line" | grep -oE '[0-9]+ passed' | grep -oE '[0-9]+' || echo "")
  fail=$(printf '%s' "$line" | grep -oE '[0-9]+ failed' | grep -oE '[0-9]+' || echo 0)
  if [ -z "$head_n" ]; then cur="GIT WILL NOT RUN — cannot count steps"
  else
    done_n=$((head_n - BASE))
    if [ -z "$pass" ]; then cur="SUITE WILL NOT RUN — step $done_n/$STEPS"
    elif [ "$done_n" -ge "$STEPS" ] && [ "$fail" -eq 0 ]; then cur="ALL $STEPS STEPS DONE — $pass passing"
    else cur="step $done_n/$STEPS — $pass passing, $fail failing"; fi
  fi
  [ "$cur" != "$prev" ] && { echo "$cur"; prev="$cur"; }
  case "$cur" in
    ALL*) stable=$((stable+1)); [ "$stable" -ge 2 ] && { echo "all steps complete — ending"; break; } ;;
    *) stable=0 ;;
  esac
  sleep 60
done
```

**Work spanning files you cannot enumerate in advance** — `git diff HEAD --numstat` needs no list,
which is the point. A hand-listed probe is blind to any file you failed to anticipate, and that is the
specific way it goes wrong: you pick the list from where you *expect* writes, and the agent writes
where its *instruction* pointed. Verified once, n=1 — a probe on four named files read all zeros for
12 minutes because the agent's first write went to a fifth.

**`git diff HEAD`, never bare `git diff`.** Bare `git diff` compares the working tree to the *index*,
so anything staged vanishes from the probe — and the orchestrator committing its own work beside a
running agent is the normal shape of these watches, not a corner case. Measured: staging one of two
changed files took the probe from `2 changed (+4)` to `1 changed (+1)`, which reads as an agent
*undoing* its work. `git diff HEAD` compares against the commit and is otherwise identical.

Untracked files are invisible to either form, so count them separately or the first *new* file reads
as no progress — an agent writing a fresh document is the common case here, not the exception. With
`HEAD` the two terms hand off cleanly: staging a new file moves it out of the `??` count and into the
numstat count in the same sample, so the total never dips.

```bash
REPO=/absolute/path/to/worktree          # a literal, not an inherited cwd — see below
prev=""; still=0
for _ in $(seq 1 40); do
  if ! git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
    cur="PROBE CANNOT RUN — $REPO is not a git worktree"
  else
    ns=$(git -C "$REPO" diff HEAD --numstat)   # HEAD, or staging hides the work
    new=$(git -C "$REPO" status --porcelain | awk '/^\?\?/ {n++} END {print n+0}')
    files=$(printf '%s\n' "$ns" | awk 'NF {n++} END {print n+0}')
    ins=$(printf '%s\n' "$ns" | awk '{s+=$1} END {print s+0}')
    names=$(printf '%s\n' "$ns" | awk '{n=split($3,p,"/"); printf "%s ", p[n]}')
    cur="$files changed (+$ins), $new new  [$names]"
  fi
  if [ "$cur" != "$prev" ]; then echo "$cur"; prev="$cur"; still=0; else still=$((still+1)); fi
  [ "$still" -eq 10 ] && echo "nothing written in 7.5 min — reading, blocked on a permission prompt, or hung; the harness notifies on exit either way"
  sleep 45
done
echo "watch ended — liveness only; read the agent's result for correctness"
```

**`git -C "$REPO"`, not `cd "$REPO"` at the top.** A leading `cd` is a one-shot: it establishes the
target once, at arming time, and every sample afterwards depends on it having worked and on the
directory still existing. When it *doesn't* work the loop does not stop — the script continues in
whatever directory the monitor inherited, and if that happens to be a git worktree too then every
probe answers confidently about the wrong repo. Demonstrated: after a deliberately failed `cd`,
`git rev-parse --git-dir` still returned a valid git dir, because the inherited cwd was itself a
worktree. bash *does* reject `cd ""` with `null directory`, so the guard fires on an unset variable —
but only if the guard is reached, and a `cd` whose failure is swallowed anywhere leaves no trace at
all. `git -C` carries the target on every invocation, so a wrong or vanished path fails on every
sample instead of once, and the "cannot run" branch does the reporting rather than a guard that has
already scrolled past. Verified once, n=1, one author, 2026-08-07.

The other two recipes have no `cd` at all, which is the same exposure without the guard: they inherit
whatever directory the monitor was started in. Give every `git` call `-C`; where the probe genuinely
needs a working directory — `pnpm` resolves its project from cwd — pin it with an explicit `cd` whose
failure branch you can point at, rather than letting it default.

Emit basenames: knowing *which* target moved is most of the value, where a bare count says only that
something happened. Insertions are not monotonic — an agent correcting records removes lines too — so
report the delta and do not treat a decrease as an anomaly once `HEAD` has ruled out the staging
artefact above; a genuine shrink is ordinary work. Counting is `awk` rather than `grep -c`
because `grep -c` prints `0` *and* exits 1, so the reflexive `|| echo 0` emits two zeroes and splits
the status line in half.

### What a curve showed once

One run, n=1, and the strongest evidence the pattern has. An implementation agent watched on
files-plus-test-count in a single status string:

```text
4 files +96  — RED 16 failing, 531 passing     ← baseline: the prior wave's tests
5 files +137 — RED 16 failing, 531 passing     ← implementation starts
5 files +213 — RED 16 failing, 531 passing
6 files +233 — RED 55 failing, 492 passing     ← 39 previously-green tests break
6 files +280 — RED 16 failing, 531 passing     ← recovered, no test file touched
6 files +306 — GREEN 547 passing
```

The spike is the finding. Thirty-nine green tests broke when a rendered element was added
unconditionally, then recovered when its condition landed. A final report shows 547 passing either
way — whether the condition was added or the assertions were adjusted to accommodate the regression.
Only the curve separates them, and recovery *before* green is what says the fix went into the
implementation. Combining both probes is what made it legible: file counts alone show movement, and
the test count alone shows the spike but not that no test file moved during the recovery.

**State suspicion criteria in terms the sampling interval can decide.** Before this ran, the watcher
wrote down "question a jump from 16 failing to 0 in one sample" — and that is exactly what the last
two samples show, benignly, because a 45-second sample spans several edits. The probe resolves
intervals, not edits. A criterion the sampling rate cannot decide will either raise a false alarm or
be quietly dropped when it fires.

## Constraints

- **Three verdicts, not two.** A watch that ends without observing the transition is *inconclusive*,
  not successful. Report it that way rather than rounding up to done.
- **Some work admits no non-vacuous terminal condition — arm those as liveness only.** For a docs-only
  agent the test count cannot move, the commit count cannot move if it was told not to commit, and the
  artifact *is* the deliverable, so volume is the only external signal and volume cannot distinguish
  "wrote it" from "wrote it correctly". Give it a timeout, no terminal condition, and a closing line
  saying outright that it shows movement rather than success. This is not a fourth verdict: its verdict
  is *inconclusive by construction*, which is why the report must say so — a timeout otherwise reads as
  done. It stays inside the arming rule at the top only because completion still comes from the
  harness and correctness from reading the result; the watch covers the middle and nothing else.
- **Watching N agents in one monitor needs N stall counters.** A single combined status string means
  any agent's movement resets the shared counter, so a busy agent masks a stalled one — and the notice
  then fires late, on whichever agent happens to be quiet once the others stop. Either track `still`
  per target, or arm one monitor per agent and accept the extra events.
- Never report the monitor's terminal event as proof the work succeeded — it proves the probe's
  condition held. Read the agent's actual result too.
- Poll remote APIs no faster than every 30s; local checks 30–60s. One event per sample is spam, and
  monitors producing too many events get suppressed automatically.
- If no cheap external probe exists, say so rather than inventing a weak one. A watch on the wrong
  signal is worse than an honest "this will be silent for 20 minutes".
- **A watch does nothing about a report that arrives confidently wrong**, which is the larger problem
  and an orthogonal one. Agent claims still have to be checked against the cited `file:line`. Do not
  describe a watch as reducing that, and do not let a clean curve stand in for reading the diff.
- **Probe the artifact, not the agent's account of it.** A task list, a progress file, a status line
  the agent maintains — these are self-reports, so probing them re-reads the same claim from a second
  location and adds no independent evidence. Tests, commits and build output were produced by the
  work rather than described by it, which is what makes them worth sampling. Use the structured task
  list to see *what the agent thinks* it has done, and a probe to see *what actually changed*; when
  they disagree, that disagreement is the finding.

## Losing the agent

The hard limit on the pattern: **a cancelled agent is invisible to every probe.** A probe measures the
artifact, and a dead agent simply stops touching it — identical to one that is reading, thinking or
stuck. The three arming questions above all presuppose the agent still exists. Three were lost in one
day and each looked the same as careful work.

**The class is states no probe can see, not cancellation alone.** An agent blocked on an unanswered
permission prompt stops touching the artifact exactly as a dead one does, so it is equally invisible —
the difference is that it is alive and clears in one click, which is why it is worth ruling out first.
Whether a liveness ping reaches an agent parked on a dialog is untested. Observed once, n=1, one
author, 2026-08-06.

- **The mechanism, twice observed, is the Claude Code process exiting.** Agents in flight do not
  survive it, and no completion notification arrives. The harness's own post-restart summary cannot
  distinguish UI stop, SDK interrupt, teardown and process exit, because none leaves a transcript
  marker.
- **`SendMessage` is the only liveness test that reaches the agent itself** — everything else observes
  its output. It returns `was stopped and won't be resumed` for a dead one, the fact no probe can
  supply. Instruct it to *report only and not write*, or a resumed agent and an orchestrator taking
  over collide on the same files.
- **After any interrupt or restart, re-check every agent dispatched before it.**
- **Work written incrementally to disk survives; a report does not.** A test-authoring agent lost this
  way left most of its output usable, where a reviewer lost the same way left nothing, its entire
  product having been the final message. Worth weighing when choosing what to delegate late in a
  session.

**When to check in** — three signals, not a clock. Duration alone picks the wrong moment in both
directions: against the one real stall, ×10 of that agent's longest prior run would have waited nearly
four hours on an agent already dead, while ×3 of its median would have fired at 30 minutes, inside the
normal range for its comparable runs of 8, 10 and 23 minutes.

**Precondition: first ask whether a permission prompt is waiting.** It is free to check, instantly
clearable, and cheapest to rule out — so it comes before the signals rather than joining them.
Observed once, n=1, one author, 2026-08-06: a background research agent sat 7.5 minutes with no writes
because a subagent it had nested needed `WebSearch` and `WebFetch`, and every signal below was either
ambiguous or unavailable while the true cause was in none of them.

**But the answer may not exist, so a "no" does not rule it out.** Asked directly during a stall,
2026-08-07: *"I click on prompts so automatically now, I couldn't tell you whether there had been
one."* Clearing a dialog is reflexive for anyone who has used the tool for a while, and reflexes do
not lay down a memory — so "no" and "I don't know" arrive as the same answer and neither is evidence.
Ask anyway, because a *yes* is instantly actionable and costs one click. Just do not treat a
non-affirmative as having eliminated anything, and do not let it upgrade the remaining signals.
n=1, one author, 2026-08-07.

Then check in when all three hold:

1. **No artifact movement** for the probe's stall window. Treat the notice as a prompt to look, not a
   verdict — it produced two false alarms in one day.
2. **Elapsed time past that agent's own comparable range**, roughly 2–3× its longest prior run on
   similar work. Where there are no prior runs, this signal is unavailable — say so rather than
   inventing a threshold, and lean on the other two.
3. **The work is visibly incomplete** — the strongest of the three, and the one worth waiting for.
   "One of five targets written, then nothing" justifies a check-in far better than any duration,
   because it separates an agent that is thinking from one that stopped having started.

All three outcomes are worth the round trip: a reply (alive — and its answer to *"are you blocked on
something the brief did not anticipate?"* may change what you do, not merely who does it); continued
silence (still ambiguous, but now knowingly); or `was stopped and won't be resumed`, which is the
whole reason this section exists.

## nWave / DES specifics

Personal-practice details, deliberately kept out of the pattern above because they do not generalise:

- `nw-deliver` is the per-unit case: RED→GREEN→COMMIT per roadmap step, so take `STEPS` from
  `roadmap.json`.
- Do not probe `deliver/execution-log.json` from Bash. A DES pre-bash hook blocks any command whose
  text merely *contains* that filename, so the natural probe cannot be written at all — read it with
  the `Read` tool before arming instead.
