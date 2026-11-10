---
name: buildy
description: Orchestrate the standard feature-build sequence — nw-auto to launch or resume a Request, nWave's own mandatory role dispatch, a watch during delivery, and gh-stack/ship for anything independently shippable. Use when starting or resuming feature work end-to-end, rather than invoking nWave steps one at a time by hand.
---

Sequence the pieces that already exist. This skill is glue, not new logic — it does not
reimplement `nw-auto`, the nWave roles, `watch`, `story`/`red`/`green`/`refactor`, or `ship`/
`gh-stack`. It stays out of nWave's own sequencing (`nw-auto` chooses waves, rework and the next
operation from evidence; nwdes keeps no workflow state) and only owns the checkpoints *around* it:
entry, the delivery watch, cost calibration, and exit.

Written for nWave 4.x (checked against v4.1.0). The 3.x commands `nw-new`, `nw-continue`,
`nw-execute`, `nw-fast-forward`, `roadmap.json` and `execution-log.json` no longer exist.

## State machine

| State              | Trigger                                             | Action                                                                                                                                                       | Owner                             | Next state                                          |
| ------------------ | ---------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- | ---------------------------------------------------- |
| `ECOSYSTEM_CHECK`   | New work described, before anything else             | `grep -q '"enabled": *true' .nwave/config.json` in the project root. **Enabled** → `REP_STYLE_CHECK` toward `TRIAGE` (nWave path). **Absent or not enabled** → `REP_STYLE_CHECK` toward `LIGHT_TRIAGE` (this repo's own `story`/`red`/`green`/`refactor`/`review`/`ship` pipeline) — nWave's roles and `nwdes` are not activated on a project that never ran `nwave-ai project enable` | this skill                         | `REP_STYLE_CHECK`                            |
| `REP_STYLE_CHECK`   | Ecosystem check resolved, before dispatching any fix or build work | Ask once per task which learning-rep style applies. **Default, no question needed if the invocation is silent on it**: full delegate — today's behaviour, unchanged. **`predict-first`** (the only style implemented so far — see "Learning-rep styles" below): capture a one-line hypothesis before continuing — suspected cause, which file or area the fix will touch — and append it to `.claude/rep-calibration.jsonl` (create if absent) with a timestamp, the task description, the hypothesis, an inferred domain (top-level directory of the named area), and status `PENDING` | this skill                         | `TRIAGE` / `LIGHT_TRIAGE`, per the path `ECOSYSTEM_CHECK` resolved |
| `TRIAGE`            | Ecosystem check passed (nWave enabled)               | Classify before invoking anything. **Obvious bug, root cause unknown** → `BUG_FIX`. **Obvious refactor** (structure/quality change, no intended behaviour change) → `REFACTOR`. Everything else (new capability, ambiguous shape) → `NO_FEATURE`/`FEATURE_IN_FLIGHT` per `docs/feature/{id}/handoff.json` existence | this skill                         | `BUG_FIX` / `REFACTOR` / `NO_FEATURE` / `FEATURE_IN_FLIGHT` |
| `LIGHT_TRIAGE`      | Ecosystem check failed (no nWave)                    | **Stack check first**: does this project actually have Vitest/TS (`package.json` naming `vitest`, a `tsconfig.json` or `.ts` sources)? `red`/`green` are written for that stack specifically — if it's absent (a Bash/Python/other project with no nWave either), say so and stop rather than invoking them blindly; this skill has no non-JS TDD cycle to fall back to. If the stack matches: needs scoping (non-trivial new capability, requirements unclear) → `story` first. Already clear (a bug, a small well-understood change) → straight to `LIGHT_CYCLE` | `story` or this skill              | `LIGHT_ORACLE` (after `story`, when chosen) or `LIGHT_CYCLE` |
| `LIGHT_ORACLE`      | `story` produced acceptance criteria. **PROPOSED, opt-in, default off.** Ask once per task; no answer means off | Dispatch an independent `general-purpose` agent (model: opus), not the main session, to turn the story's acceptance criteria into executable acceptance tests in the project's own test layout, and run them to observe RED first. These tests are a frozen oracle: the main session never edits them, only production code, and if one looks wrong it stops and asks the owner (Test Modification Prohibition). Unit-level `red`/`green` in `LIGHT_CYCLE` is unchanged. Say the dispatch out loud first; if `~/.claude/token-budget.md` exists follow it as the cost check | acceptance-test agent (Agent) | `LIGHT_CYCLE`, which ends only when the frozen tests are GREEN too |
| `LIGHT_CYCLE`       | Scope is clear, stack confirmed                      | `red` → `green` → `refactor`, one test at a time (root `CLAUDE.md`'s TDD Rhythm — never batch multiple tests before seeing each fail individually)             | `red`/`green`/`refactor`           | `CHECK`                                              |
| `CHECK`             | Implementation green                                 | Run the full quality gate — lint, typecheck, coverage — not just the tests `green` already proved. If `.claude/rep-calibration.jsonl` has a `PENDING` entry for this task, score it now, per "Learning-rep styles" below, before moving on                | `check`                            | `LIGHT_REVIEW`                                       |
| `LIGHT_REVIEW`      | `check` passed                                       | Dispatch an independent reviewer agent — **not** self-review. Same independent-perspective reason nWave's `*-reviewer` gates are mandatory; running it inline as the main instance re-checking its own work is the exact case the Delegation Budget carves out as invalid | `pr-review-toolkit:code-reviewer` (Agent) | `ADVERSARIAL_CHECK` (when eligible) or `SHIP_READY` |
| `ADVERSARIAL_CHECK` | `LIGHT_REVIEW` passed. **PROPOSED, opt-in, default off** — see "Adversarial check" below | **Eligible only if** the change has an external surface (CLI, parser, API) with a source of truth independent of the code, and `docs/target-profile.md` exists. Refactor and prose changes skip. Not eligible → no question, straight on. Eligible → ask once per task; no answer means off. On yes: say the dispatch out loud, and if `~/.claude/token-budget.md` exists follow it as the cost check. Dispatch one `general-purpose` agent (model: opus) with the artefact paths, the run command and the target profile, withholding the implementation reasoning, the tests and the review report. It attacks through inputs only, never edits, and returns reproducible failures. Each failure the tests let through is an oracle gap (the tests did not check what was promised): add it as a test observed RED, repair, GREEN, one `fix(...)` commit. Re-run `check` after a repair. `buildy` adds no loop of its own: one pass per task | adversarial agent (Agent) | `SHIP_READY` |
| `BUG_FIX`           | Triaged as an obvious bug with unknown root cause    | Invoke `nw-bugfix` directly. It gives the defect verbatim to the Product Owner, then runs a regression oracle observed RED on the pre-fix source, the fix, GREEN, and an examiner observation of the fix. A defect whose root cause is already established, found *during* current work, is not a Request of its own: fix it in place in the current lane (regression test RED, fix, GREEN, one separate `fix(...)` commit), per `nw-auto`'s recovery table | `nw-bugfix`                        | `DELIVER_PENDING` once it is about to dispatch the crafter |
| `REFACTOR`          | Triaged as an obvious refactor                       | Invoke `nw-refactor` directly. It plans L1–L6 in cascade order, applies one batch, and runs the suite once at the end; a RED batch is fixed in production code, never by editing tests | `nw-refactor`                      | `DELIVER_PENDING` once it's about to write changes  |
| `NO_FEATURE`        | New work, no matching `docs/feature/{id}/handoff.json`, and not triaged to `BUG_FIX`/`REFACTOR` | Invoke `nw-auto` with the Request. It states a working S/M/L assessment and the fastest route that keeps what the Request must leave behind; the human decides scope and trade-offs. Ask once for interactive vs autonomous at the start of an epic | `nw-auto`                           | `IN_REQUEST`                                         |
| `FEATURE_IN_FLIGHT` | `docs/feature/{id}/handoff.json` already exists      | Invoke `nw-auto` to resume: it reads the handoff and the briefs from `nwdes document`, reusing only still-applicable role assessments. Never infer progress from a stored workflow state — there is none | `nw-auto`                           | `IN_REQUEST`                                         |
| `IN_REQUEST`        | Inside a Request, before delivery                    | Nothing new here — root `CLAUDE.md`'s "nWave agents are mandatory" rule already forces each installed role and the `*-reviewer` gate. `nw-auto` picks the route (spine waves, host-led nwdes steps, or working directly) from what must survive the session and what a late refusal would cost, and goes upstream (`nw-discuss`, `nw-design`) only when evidence shows authority is missing. Do not re-model this step | installed `nw-*` roles + reviewers | `DELIVER_PENDING` once acceptance authority exists and a crafter is about to be dispatched |
| `DELIVER_PENDING`   | About to dispatch the crafter                        | **Baseline line first**: `nw-auto`'s visible-baseline rule (`Baseline: GREEN/RED/INDETERMINATE — <evidence> (<scope>)`); RED or INDETERMINATE stops affected work. **Cost-check gate:** if `~/.claude/token-budget.md` exists, follow it — calibrate `nw-rigor`, say the role/agent count out loud before dispatch | this skill                         | `DELIVER_RUNNING`                                    |
| `DELIVER_RUNNING`   | Crafter dispatched                                   | `run_in_background: true`, then arm a `Monitor` per `watch`'s own "nWave specifics" recipe — units are the slices in `docs/feature/{id}/handoff.json`. The Request is not done when the crafter finishes: it ends when the final whole-candidate review and the source-blind EXAMINE accept the composed candidate (`nw-auto` §10) | `nw-deliver` + `watch` | `SHIP_READY` (review and EXAMINE accepted) or a check-in per `watch`'s stall criteria |
| `SHIP_READY`        | nWave path: final whole-candidate review and EXAMINE accepted. Light path: `LIGHT_REVIEW` passed, and `ADVERSARIAL_CHECK` done or skipped | If `.claude/rep-calibration.jsonl` has a `PENDING` entry for this task, score it first, per "Learning-rep styles" below — `SHIP_READY` is the first point after the fix where the diff is settled. **Docs check next**: invoke `docs-review` before anything else, unless this run was triaged as `REFACTOR` (no intended behaviour change — nothing for docs to have drifted against). Covers `NO_FEATURE`/`FEATURE_IN_FLIGHT`, `BUG_FIX`, and the light path's `LIGHT_CYCLE` alike, since only `REFACTOR` is excluded. On the nWave path, commit any docs fix in the lane *before* the next step, because integration moves trunk. Then: **nWave path** → `nwdes lane compose`, then `nwdes lane integrate --expected <id> --candidate <id>` (see "Shipping" below). **Light path** → `ship`'s own step 2 draft PR (opened at branch creation) reaching step 10, ready-for-review | `docs-review` (unless `REFACTOR`), then `nwdes lane` (nWave) or `ship` / `gh-stack` (light) | `SHIPPED`                                            |
| `SHIPPED`           | nWave path: lane integrated into local trunk, CI green on trunk. Light path: PR open | nWave path: **ask before pushing trunk**, then push. Then `/done` if the session is closing; otherwise loop to `ECOSYSTEM_CHECK` for the next piece of work | `done`                              | `ECOSYSTEM_CHECK`                                    |

**Shipping, trial from 2026-11-04: vanilla nWave lanes, no PR on the nWave path.**
nWave 4 has no pull-request or push step, and `nwdes` never commits or publishes. The nWave path
follows its own flow: `nwdes lane open --feature <id>` (needs `{"lanes": {"trunk": "main"}}` in
`.nwave/config.json`), the Request, then `nwdes lane compose` (merges trunk into the lane and prints
EXPECTED and CANDIDATE commit ids) and `nwdes lane integrate --expected --candidate`, which
fast-forwards local trunk and removes the lane. CI then gates the push of trunk, not the
integration (`nw-throughput`). Ask before pushing trunk. The light path keeps `ship`'s PR flow.

This is a tracked exception to `ENGINEERING-DEFAULTS.md`'s "never commit to `main`": the commits
were made and reviewed in the lane, and `integrate` only moves trunk's ref forward. Record what
goes wrong — a rejected push to a protected `main`, a missed review, a lingering lane — as it
happens, so the trial can be revisited with evidence
(`docs/decisions/DR--20261104--process--nwave-lane-integration-trial.md`).

**Layers are sequential Requests.** `nw-auto` §6 splits work into an ordered sequence of Requests
when values need different durable authorities or a late refusal would throw away more than one
value: walk one Request, read its integrated commit, then start the next. Each lane opens at the
trunk the previous Request just integrated into, so there is no stack to manage. `gh-stack` stays
available on the light path, which has no lanes.

The earlier decision, `docs/decisions/DR--20260907--process--spec-ladder-placement.md`, was made
for nWave 3 (`nw-deliver` pushing one branch, layers scoped as roadmap-sized slices in DISTILL). Its
premise no longer holds; it needs its own revisit. The rigor calibration this skill's
`DELIVER_PENDING` gate reads from `token-budget.md` is captured in
`docs/decisions/DR--20260907--process--nwave-rigor-profile-org-device.md`.

## Learning-rep styles

A prototype. Only `predict-first` is implemented. Motivation: agentic delivery can silently
remove the reps that used to build and maintain judgement, and that only shows up later, as
decayed calibration nobody was tracking. `predict-first` makes one rep — hypothesising before
you see the answer — cheap enough to survive delivery pressure, by making it a checkpoint this
skill already owns rather than a discipline someone has to remember.

**Capture, at `REP_STYLE_CHECK`.** Before dispatching `LIGHT_CYCLE` or `DELIVER_PENDING`, if the
style is `predict-first`, ask for one line: what's the suspected cause, and which file or area
the fix will touch. Do not coach the answer or suggest a better one — a hint here defeats the
point. Append one JSON line to `.claude/rep-calibration.jsonl` (create the file if it does not
exist):

```json
{"timestamp": "<ISO8601>", "task": "<one-line task description>", "hypothesis": "<verbatim answer>", "domain": "<top-level dir of the named area>", "status": "PENDING"}
```

**Score, at `CHECK` or `SHIP_READY`.** Once the diff exists, find the matching `PENDING` line for
this task and compare it against what actually happened: did the change land in the predicted
file or area, and did the actual cause match the predicted one. Update that line in place —
`status` becomes `HIT`, `PARTIAL` (right area, wrong cause, or vice versa), or `MISS` — and add a
`scored_at` timestamp. Score objectively against the diff, not against how good the hypothesis
sounds; softening a miss into a partial to be kind defeats the log's entire purpose.

**Report.** After scoring, read back every entry in `.claude/rep-calibration.jsonl` sharing this
entry's `domain`, and say the hit-rate out loud — `"predict-first, <domain>: 3 of 5 (60%)"` — not
as a verdict, just as the number. A rising or falling rate over time is the actual signal; a
single score is not.

**Prompt, never draft, on a `MISS` or `PARTIAL`.** If `.claude/LESSONS.md` exists in this project,
ask — do not write — whether this gap is worth a dated entry there, in the developer's own words.
The whole point of the file is the generation effect: a lesson the agent writes only sharpens the
agent. Offer the prompt once per scored miss and move on either way; do not chase a "no."

**What this does not do yet.** `human-red`, `fault-injection`, `faded-scaffold`, and
`explain-before-reveal` are named but unbuilt. They need changes inside `red`/`green`/`refactor` or
the nWave roles themselves, which this skill does not reach into by design (see Constraints).
`adversarial-review` is built as the PROPOSED `ADVERSARIAL_CHECK` state, light path only.

## Adversarial check

PROPOSED, untested until piloted (`docs/decisions/DR--20261110--process--light-path-adversarial-trial.md`).
`review` and EXAMINE confirm that agreed promises were kept. This checkpoint tries to break the
change against a source of truth that is independent of the artefact.

- **Needs a `docs/target-profile.md`, written by a human.** Nothing generates it. Sections: system
  under test, how to run it, knobs, source of truth, hostile traits, attack list. Without one the
  state is skipped, not improvised.
- **Measure: yield.** Record findings the check made that `LIGHT_REVIEW` had accepted past. A
  check that finds nothing in three eligible tasks is evidence to drop it.
- **Origin.** Modelled on the `sniper` agent in `swarm-of-experts-demo`. One recorded run there
  found 5 findings after a validator PASS; that is one data point, not a rate. Its claim that
  self-review is "measured" to be worse has no source in that repository's `sources.md`: NOT KNOWN.

## Constraints

- Do not silently widen "hand off to agents" beyond nWave's own mandatory role dispatch —
  everything else stays under the Delegation Budget.
- Do not invent a stacking or shipping mechanism around nWave's lane verbs — they are vendored, and
  patching them is a separate decision. On the nWave path `buildy` runs them as specified.
- This skill sequences `nw-auto`/`nw-bugfix`/`nw-refactor`, the existing mandatory role dispatch,
  `watch`, `story`/`red`/`green`/`refactor`/`check`, and `ship`/`gh-stack`. One
  deliberate exception to "no new agent": `LIGHT_REVIEW` names `pr-review-toolkit:code-reviewer`
  explicitly, because the light path has no nWave `*-reviewer` gate to inherit and would otherwise
  have no independent check at all. `review/SKILL.md` itself is unchanged and still available for
  a quick manual self-review outside this pipeline — this is `buildy`'s own automated path
  choosing the independent-agent option instead of it.
- **`ADVERSARIAL_CHECK` would be a second agent exception (PROPOSED).** In the swarm, the sniper's
  blindness to the builder's reasoning and the validator's tests is enforced by hooks. Here it is
  enforced only by what the dispatch prompt withholds, so a leak would go unnoticed. The state is
  opt-in and gated by the cost check for that reason.
- **`LIGHT_ORACLE` is PROPOSED and prose-enforced (`docs/decisions/DR--20261110--process--light-path-adversarial-trial.md`).**
  It exists because `red` targets a unit, so the light path alone may leave new behaviour without an
  acceptance-level test, which the global rule requires. Whether it does is NOT KNOWN until piloted.
  `claude/hooks/test-guard.sh` only reports weakening marks and never blocks, so nothing stops the
  main session editing a frozen test except this rule. It is a third agent exception beside the two above. The light path
  deliberately uses no nWave role for it.
- **`TRIAGE`'s bar is "obvious."** An ambiguous bug-or-feature or refactor-or-redesign call
  defaults to `NO_FEATURE`/`nw-auto` — that's more scrutiny, not less, and matches Inference
  Discipline (don't generalise a routing decision from a thin signal).
- **`ECOSYSTEM_CHECK` is a filesystem fact (`.nwave/config.json` enabled or not), never a judgment
  call.** Do not reach for the nWave path in a project that hasn't activated it, and do not reach
  for `story`/`red`/`green`/`refactor` in one that has — the two pipelines are not interchangeable
  by preference.
- The light path has no `nw-rigor`/`token-budget.md` cost gate to read — there is no nWave role
  machinery underneath it to calibrate. If `LIGHT_CYCLE` work is itself delegated to a background
  agent, the Delegation Budget and `watch` still apply on their own terms; this skill does not
  invent a light-path equivalent of `DELIVER_PENDING`. The one exception is the PROPOSED
  `ADVERSARIAL_CHECK`, which reads `token-budget.md` before its own dispatch.
- **`SHIP_READY`'s docs-review gate excludes only `REFACTOR`.** A refactor has no intended
  behaviour change by definition, so there's nothing for docs to have drifted against. A bug fix
  is included on purpose — fixing behaviour is exactly the kind of change that leaves docs
  describing the old, wrong behaviour, and `docs-review`'s own trigger ("user-facing behaviour,
  wording, or a tracked decision") applies to it as much as to a new feature. The light path is
  included too, for the same reason: it has no `REFACTOR` classification to exempt it, and a
  well-understood small change can still be user-facing.
- **Sequential IDs are no longer gated here.** `nwdes lane rekey` renumbers a lane-added ADR that
  collides with trunk. Story IDs (`US-N`) have no equivalent in v4.1.0; check sibling worktrees by
  hand if two lanes both run DISCUSS (`docs/decisions/DR--20261104--process--retire-id-collision-gate.md`).
- **`REP_STYLE_CHECK` asks once per task, never assumes carry-over.** A style chosen for one task
  is not a standing mode — ask again next time, even in the same session. A default nobody
  re-confirms is silent drift.
- **`predict-first` never rounds a miss up to spare the moment.** The hit-rate is only worth
  reading later if every entry in `.claude/rep-calibration.jsonl` was scored the same
  way — against the diff, not against how the hypothesis reads.
