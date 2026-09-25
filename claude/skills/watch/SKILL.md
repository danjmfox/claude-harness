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

Every arm-or-decline call above is a judgment made in advance, with no feedback loop. **Recording the
cost verdict**, below, is how that judgment gets checked against what actually happened.

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
5. **When the harness's own completion notification for the watched agent arrives, check whether the
   Monitor is now redundant and `TaskStop` it if so.** The self-terminating recipes below cover the
   case where the probe's own terminal condition fires first; they do nothing for the reverse — the
   agent finishing before the probe next samples, a plan change that means the literal `STEPS` is
   never reached, or any other race. A non-persistent Monitor still dies at its `timeout_ms`, but a
   `persistent: true` one runs until `TaskStop` or the session ends — so for that case, this step is
   not a courtesy, it is the only thing that ends it.
6. **Log a `WATCH-COST` verdict once the watch ends** (see **Recording the cost verdict** below) —
   every time, not only when the watch clearly paid off.

## The terminal condition is the hard part

The failure mode has a name: in model checking, a property that passes because its precondition was
never exercised is **vacuous**, and the special case where the precondition is unsatisfiable is
**antecedent failure** ([Beer, Ben-David, Eisner & Rodeh, FMSD 18(2):141–163,
2001](https://www.cs.toronto.edu/~chechik/courses05/csc2108/beer01.pdf) found trivial validity always
indicated a real defect in the design, spec, or environment). A watch that ends on a condition the
work never had to cause is the same defect.

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
4. **Could the condition ever become true at all?** The three above ask whether the terminal is too
   *easy*; this asks whether it is *possible* — an unsatisfiable terminal runs to timeout on finished
   work and reports a **stall**, which looks identical to death.

   The known trap: a probe's pattern matching prose *about* the artifact as well as the artifact
   itself — counting `it.skip` markers also counted a header comment naming them, giving the count a
   nonzero floor it could never clear. Anchor patterns to the artifact's own syntax (`^\s*it\.skip`,
   not `it\.skip`) so they can't match a sentence describing the thing being counted. The same trap
   waits in any count of `TODO` or a deprecated symbol — each tends to name itself in the docs
   discussing it.

   **Check the floor first:** measure the baseline with the probe command itself before arming. If
   the number can't reach its terminal value from where it starts, the watch is unsatisfiable — and
   you find out in one command instead of twenty silent minutes.

**Sampling a target being edited underneath you** is the database read-skew problem — the probe can
observe a state that never coherently existed. Require N consecutive agreeing samples before
believing a state, the same device as Prometheus' `for` clause. When a count moves in a direction the
work should make impossible, re-sample rather than conclude; the movement is evidence about the
observation, not the work.

**A probe that writes is not a probe.** Running the project's own test suite is the natural probe,
but it's also the most likely to share mutable scratch space with the agent running that same suite
on its own schedule — two concurrent runs can corrupt shared fixtures and the resulting flake looks
like the agent's bug. Prefer probes that only read (`git` plumbing, `grep`, file counts); reach for
the suite only after checking what it writes, and know you've coupled observer to observed if nothing
else will do.

## Recipes

All emit on change only and have a "will not run" branch. The first two run `pnpm test` as the probe
— read the write-side-effect caution above before copying either onto a repo whose suite touches
shared scratch space. The rest read `git`, the filesystem, or a remote API instead, and don't carry
that risk.

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

A dynamically-derived count carries the same risk: a probe filtering on the wrong field name against
a live schema (`step_id` when the schema actually uses `id`) matches nothing and reports the file as
unwritten — indistinguishable from a missing file, and caught only by the commit ordering looking
wrong on inspection, not by the probe complaining.

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
which is the point. A hand-listed probe is blind to any file you failed to anticipate: you pick the
list from where you *expect* writes, and the agent writes where its *instruction* pointed.

**`git diff HEAD`, never bare `git diff`.** Bare `git diff` compares the working tree to the *index*,
so anything staged vanishes from the probe — and staging one changed file can make a two-file diff
read as the agent *undoing* work. `git diff HEAD` compares against the commit and avoids this; the
orchestrator committing its own work beside a running agent is the normal shape here, not a corner
case.

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

**`git -C "$REPO"`, not `cd "$REPO"` at the top.** A leading `cd` is a one-shot: every sample
afterwards depends on it having worked and the directory still existing. If it silently fails, the
loop keeps running in whatever directory the monitor inherited — and if that's also a git worktree,
every probe answers confidently about the wrong repo. `git -C` carries the target on every
invocation, so a wrong or vanished path fails on every sample, and the "cannot run" branch does the
reporting instead of a guard that already scrolled past.

The other recipes above have no `cd` at all, which is the same exposure without even a guard. Give
every `git` call `-C`; where a probe genuinely needs a working directory (`pnpm` resolves its project
from cwd), pin it with an explicit `cd` whose failure branch you can point at, rather than letting it
default.

Emit basenames: knowing *which* target moved is most of the value, where a bare count says only that
something happened. Insertions are not monotonic — an agent correcting records removes lines too — so
report the delta and do not treat a decrease as an anomaly once `HEAD` has ruled out the staging
artefact above; a genuine shrink is ordinary work. Counting is `awk` rather than `grep -c`
because `grep -c` prints `0` *and* exits 1, so the reflexive `|| echo 0` emits two zeroes and splits
the status line in half.

**A single known artifact, no git or test signal** — for a docs-only wave with exactly one output
file (a feature-delta, an ADR, a roadmap draft), skip git and test entirely: poll the file's own
size. Simpler than numstat when there's only one target.

```bash
FILE=/absolute/path/to/output.md
prev=""; still=0
while true; do
  if [ ! -f "$FILE" ]; then cur="FILE NOT YET WRITTEN"
  else
    lines=$(wc -l < "$FILE" | tr -d ' '); bytes=$(wc -c < "$FILE" | tr -d ' ')
    cur="$lines lines, $bytes bytes"
  fi
  [ "$cur" != "$prev" ] && { echo "$cur"; prev="$cur"; still=0; } || still=$((still+1))
  [ "$still" -eq 10 ] && echo "no growth in ~7.5min — reading/researching, blocked on a prompt, or stalled"
  sleep 45
done
```

This is liveness only — size growing says nothing about correctness, and structural presence says
even less: the scaffold bug that motivated question 4 above was exactly this shape, an empty
`## Sources` heading with zero URLs satisfying a presence check. If the file is machine-parsed rather
than prose — `roadmap.json`, a manifest — pair the size check with a validity check, because a
growing byte count mid-write can be a truncated, unparseable document rather than progress:

```bash
python3 -c "import json; json.load(open('$FILE'))" 2>/dev/null && valid=1 || valid=0
```

`valid=0` while size is still climbing is normal — the file is mid-write. `valid=0` once size has
stopped changing for several samples is the failure worth surfacing.

**External CI/PR checks settling** — not a local file or git state at all: watch a pull request's
checks resolve. The terminal is the absence of any pending state, not a specific pass/fail — report
the actual result once terminal rather than folding it into the loop's own condition.

```bash
PR=123
while true; do
  out=$(gh pr checks "$PR" 2>&1)
  if echo "$out" | grep -qiE 'pending|queued|in_progress|expected'; then
    cur="CHECKS PENDING"
  else
    cur="CHECKS SETTLED — see gh pr checks $PR for pass/fail detail"
    echo "$cur"; break
  fi
  [ "$cur" != "${prev:-}" ] && echo "$cur"; prev="$cur"
  sleep 25
done
```

Poll no faster than every 20–30s — this is a remote API, not a local file. Prefer this hand-rolled
loop over a packaged CI-monitoring tool where sandbox permissions are in question — a plugin that
needs to write a PID file can fail outright in a sandboxed session where this loop still runs.

### Why the curve matters, not just the endpoint

A completion report showing 547 passing reads identically whether a regression was fixed in the
implementation or the failing assertions were adjusted to match it. Only the intermediate curve
distinguishes them:

```text
4 files +96  — RED 16 failing, 531 passing     ← baseline
5 files +137 — RED 16 failing, 531 passing     ← implementation starts
6 files +233 — RED 55 failing, 492 passing     ← 39 previously-green tests break
6 files +306 — GREEN 547 passing               ← recovered, no test file touched
```

The spike and its recovery — with no test file touched during recovery — is what shows the fix
landed in the implementation rather than the test. Combining a file-count probe with a test-count
probe is what makes this legible: file counts alone show movement; the test count alone shows the
spike but not that no test file moved.

**The probe resolves intervals, not edits.** A single sample can span several edits, so a jump from
16 failing to 0 in one sample is not automatically suspicious — decide state-suspicion criteria in
terms the sampling interval can actually distinguish, or they'll either false-alarm or get silently
ignored when they fire.

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

## Reporting events

Six things happen during a watch, and each has earned message, one line, no restatement of the
reasoning above — the reader has already seen why a terminal-condition hit differs from full
completion; repeating that paragraph on every occurrence is the wordiness this section exists to cut.

- **Monitor's terminal condition fires:** "Probe condition met — agent's own completion still
  pending."
- **Harness reports the background task/agent done:** let the notification card speak; add nothing
  unless the result needs a qualifier ("— but see the RED spike below").
- **No movement past the stall window:** "No movement for Ns — stalled, blocked on a prompt, or
  dead."
- **Monitor times out without the terminal condition:** "Watch expired, inconclusive."
- **No safe terminal condition existed, arming declined:** "No viable probe — watching for
  completion only, no progress signal."
- **`SendMessage` confirms the agent is gone:** "Agent confirmed dead, won't resume."

Expand past one line only when asked, or when the message itself is the finding — a spike, a
disagreement between the task list and the probe. Ties back to **Three verdicts, not two** above:
the terseness is in the wording, not in collapsing inconclusive into done.

## Recording the cost verdict

The three verdicts above answer whether the *probe's own condition held*. A separate question, not
answerable in the moment and not meant to be: was arming this watch worth what it cost, against what
a plain `run_in_background` would have told you for free? Two costs are in play — loading this skill
(a fixed few thousand tokens, paid once regardless of outcome) and the Monitor's own polling (scales
with how long the watch runs). The point of tracking this per-watch, rather than deciding it once in
the abstract, is that "When to arm one" above is a set of judgment calls with no feedback loop; this
gives it one.

**Every time a watch ends, log one line, fixed format, regardless of which correctness verdict
applied:**

`WATCH-COST: <worth-it|not-worth-it|inconclusive> — <reason, ≤15 words>`

- **worth-it** — the curve or terminal condition surfaced something the completion report alone would
  have hidden: a RED spike, a per-unit terminal a plain "green" would have missed. This is the arming
  rule's own case, now recorded rather than merely asserted at arm-time.
- **not-worth-it** — the watch ran cleanly to its terminal condition, but nothing it showed was
  information a plain `run_in_background` wouldn't have given you anyway: no spike, no per-unit
  ambiguity, no disagreement with the task list.
- **inconclusive** — cost was paid but the watch never got the chance to answer the question: it
  timed out before any signal, or the agent finished before the first sample that would have mattered.

The format is fixed so a later pass can grep or search transcripts for `WATCH-COST:` and get an exact
match — the same reason probe patterns in this skill are anchored to syntax rather than left to match
prose. Log `not-worth-it` as readily as `worth-it`; it is the more useful data point for deciding
which task shapes should skip this skill entirely.

## Losing the agent

The hard limit on the pattern: **a cancelled agent is invisible to every probe.** A dead agent simply
stops touching the artifact — identical to one that is reading, thinking, or stuck. The three arming
questions above all presuppose the agent still exists.

**The class is states no probe can see, not cancellation alone.** An agent blocked on an unanswered
permission prompt stops touching the artifact exactly as a dead one does — the difference is that
it's alive and clears in one click, which is why it's worth ruling out first.

- **The mechanism is the Claude Code process exiting.** Agents in flight do not survive it, and no
  completion notification arrives. The harness's own post-restart summary cannot distinguish UI stop,
  SDK interrupt, teardown, and process exit — none leaves a transcript marker.
- **`SendMessage` is the only liveness test that reaches the agent itself** — everything else observes
  its output. It returns `was stopped and won't be resumed` for a dead one. Instruct it to *report
  only and not write*, or a resumed agent and an orchestrator taking over collide on the same files.
- **That same instruction is a trap when sent mid-work rather than on resume.** Telling a
  still-running agent to "report only, don't write" can freeze it exactly as if it had stalled — the
  liveness check causes the condition it was checking for. If a probe goes flat right after a
  check-in message, suspect the message's own wording before suspecting the agent.
- **After any interrupt or restart, re-check every agent dispatched before it.**
- **Work written incrementally to disk survives; a report does not.** A test-authoring agent's output
  stays mostly usable if lost this way; a pure-reviewer agent's entire product was its final message,
  and loses everything. Weigh this when choosing what to delegate late in a session.

**When to check in** — three signals, not a clock. Duration alone picks the wrong moment in both
directions relative to an agent's own comparable runs, so anchor to its prior range rather than a
fixed threshold.

**Precondition: ask first whether a permission prompt is waiting.** Free to check, instantly
clearable, cheapest to rule out — so it comes before the three signals below. A nested subagent
needing `WebSearch`/`WebFetch` can silently stall an outer agent this way with every other signal
ambiguous.

**A "no" does not rule it out.** Clearing a permission dialog becomes reflexive with practice, and
reflexes don't lay down a memory — so "no" and "I don't know" are the same non-answer. Ask anyway,
since a *yes* is instantly actionable, but don't treat a non-affirmative as having eliminated
anything.

Check in when all three hold:

1. **No artifact movement** for the probe's stall window — a prompt to look, not a verdict; it can
   false-alarm.
2. **Elapsed time past that agent's own comparable range**, roughly 2–3× its longest prior run on
   similar work. With no prior runs, say the signal is unavailable rather than inventing a threshold.
3. **The work is visibly incomplete** — the strongest signal. "One of five targets written, then
   nothing" justifies a check-in far better than duration alone, because it separates an agent still
   thinking from one that stopped having started.

All three outcomes are worth the round trip: a reply (alive — and worth asking *"are you blocked on
something the brief did not anticipate?"*); continued silence (still ambiguous, but now knowingly);
or `was stopped and won't be resumed`, which is the whole reason this section exists.

## nWave / DES specifics

Personal-practice details, deliberately kept out of the pattern above because they do not generalise:

- `nw-deliver` is the per-unit case: RED→GREEN→COMMIT per roadmap step, so take `STEPS` from
  `roadmap.json`.
- Do not probe `deliver/execution-log.json` from Bash. A DES pre-bash hook blocks any command whose
  text merely *contains* that filename, so the natural probe cannot be written at all — read it with
  the `Read` tool before arming instead.
