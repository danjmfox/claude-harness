---
name: buildy
description: Orchestrate the standard feature-build sequence — nw-new to launch a feature, nWave's own mandatory per-wave agent dispatch, a watch during DELIVER, and gh-stack/ship for anything independently shippable. Use when starting or resuming feature work end-to-end, rather than invoking waves one at a time by hand.
---

Sequence the pieces that already exist. This skill is glue, not new logic — it does not
reimplement `nw-new`, the wave agents, `watch`, `story`/`red`/`green`/`refactor`, or `ship`/
`gh-stack`. It stays out of nWave's own wave-to-wave sequencing (that's `nw-continue`/
`nw-fast-forward`'s job) and only owns the checkpoints *around* it: entry, the DELIVER watch, cost
calibration, and exit.

## State machine

| State              | Trigger                                             | Action                                                                                                                                                       | Owner                             | Next state                                          |
| ------------------ | ---------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- | ---------------------------------------------------- |
| `ECOSYSTEM_CHECK`   | New work described, before anything else             | `test -d .nwave` in the project root. **Present** → `REP_STYLE_CHECK` toward `TRIAGE` (nWave path). **Absent** → `REP_STYLE_CHECK` toward `LIGHT_TRIAGE` (this repo's own `story`/`red`/`green`/`refactor`/`review`/`ship` pipeline) — nWave's wave machinery and `nw-rigor` don't exist to invoke on a project that never installed it | this skill                         | `REP_STYLE_CHECK`                            |
| `REP_STYLE_CHECK`   | Ecosystem check resolved, before dispatching any fix or build work | Ask once per task which learning-rep style applies. **Default, no question needed if the invocation is silent on it**: full delegate — today's behaviour, unchanged. **`predict-first`** (the only style implemented so far — see "Learning-rep styles" below): capture a one-line hypothesis before continuing — suspected cause, which file or area the fix will touch — and append it to `.claude/rep-calibration.jsonl` (create if absent) with a timestamp, the task description, the hypothesis, an inferred domain (top-level directory of the named area), and status `PENDING` | this skill                         | `TRIAGE` / `LIGHT_TRIAGE`, per the path `ECOSYSTEM_CHECK` resolved |
| `TRIAGE`            | Ecosystem check passed (nWave present)               | Classify before invoking anything. **Obvious bug** (something is broken) → `BUG_FIX`. **Obvious refactor** (structure/quality change, no intended behaviour change) → `REFACTOR`. Everything else (new capability, ambiguous shape) → `NO_FEATURE`/`FEATURE_IN_FLIGHT` per `docs/feature/{id}/` existence | this skill                         | `BUG_FIX` / `REFACTOR` / `NO_FEATURE` / `FEATURE_IN_FLIGHT` |
| `LIGHT_TRIAGE`      | Ecosystem check failed (no nWave)                    | **Stack check first**: does this project actually have Vitest/TS (`package.json` naming `vitest`, a `tsconfig.json` or `.ts` sources)? `red`/`green` are written for that stack specifically — if it's absent (a Bash/Python/other project with no nWave either), say so and stop rather than invoking them blindly; this skill has no non-JS TDD cycle to fall back to. If the stack matches: needs scoping (non-trivial new capability, requirements unclear) → `story` first. Already clear (a bug, a small well-understood change) → straight to `LIGHT_CYCLE` | `story` or this skill              | `LIGHT_CYCLE`                                        |
| `LIGHT_CYCLE`       | Scope is clear, stack confirmed                      | `red` → `green` → `refactor`, one test at a time (root `CLAUDE.md`'s TDD Rhythm — never batch multiple tests before seeing each fail individually)             | `red`/`green`/`refactor`           | `CHECK`                                              |
| `CHECK`             | Implementation green                                 | Run the full quality gate — lint, typecheck, coverage — not just the tests `green` already proved. If `.claude/rep-calibration.jsonl` has a `PENDING` entry for this task, score it now, per "Learning-rep styles" below, before moving on                | `check`                            | `LIGHT_REVIEW`                                       |
| `LIGHT_REVIEW`      | `check` passed                                       | Dispatch an independent reviewer agent — **not** self-review. Same independent-perspective reason nWave's `*-reviewer` gates are mandatory; running it inline as the main instance re-checking its own work is the exact case the Delegation Budget carves out as invalid | `pr-review-toolkit:code-reviewer` (Agent) | `SHIP_READY`                                  |
| `BUG_FIX`           | Triaged as an obvious bug                            | Invoke `nw-bugfix` directly, **not** `nw-new`. `nw-new`'s own decision tree routes bugs to `/nw-root-why` only — RCA, no enforced fix. `nw-bugfix` runs that same RCA as its Phase 1, then a mandatory user-review stop (Phase 2), then delegates to `nw-deliver` for a regression-test-first fix (Phase 3) — routing through `nw-new` would reach the RCA and silently drop the other two phases | `nw-bugfix`                        | `DELIVER_PENDING` once its Phase 3 reaches `nw-deliver` |
| `REFACTOR`          | Triaged as an obvious refactor                       | Invoke `nw-refactor` directly. `nw-new`'s decision tree has no branch for refactors at all — routed through it, an ambiguous refactor ask falls through to `DEFAULT: -> /nw-discuss`, disproportionate ceremony for a structure-only change | `nw-refactor`                      | `DELIVER_PENDING` once it's about to write changes  |
| `NO_FEATURE`        | New work, no matching `docs/feature/{id}/`, and not triaged to `BUG_FIX`/`REFACTOR` | Invoke `nw-new`. It also routes unvalidated problems to `nw-discover` — a wave name back is not guaranteed                                                     | `nw-new`                            | `IN_WAVE` (or a routed skill, per `nw-new`'s call)   |
| `FEATURE_IN_FLIGHT` | `docs/feature/{id}/` already exists                  | Invoke `nw-continue` instead of re-running `nw-new`                                                                                                              | `nw-continue`                       | `IN_WAVE`                                            |
| `IN_WAVE`           | Inside DISCOVER…DISTILL                              | Nothing new here — root `CLAUDE.md`'s "nWave agents are mandatory" rule already forces the wave's own agent(s) and `*-reviewer` gate. Do not re-model this step. One carve-out: DESIGN and DISCUSS route through `ID_COLLISION_CHECK` first, below | wave's own `nw-*` agent + reviewer | `DELIVER_PENDING` once DISTILL's artifacts exist     |
| `ID_COLLISION_CHECK` | Inside `IN_WAVE`, about to dispatch DESIGN or DISCUSS specifically — the two waves that allocate a new sequential ID (ADR number, `US-N`) | `git worktree list --porcelain` to enumerate sibling worktrees; glob each one's relevant ID files (`docs/product/architecture/adr-*.md` for DESIGN, story files for DISCUSS), including uncommitted/untracked — a collision can exist before either side commits. If a sibling worktree already holds the number this worktree is about to allocate, **surface it and stop**; never auto-bump either side's number, since a third worktree could be racing the same check | this skill | `IN_WAVE` (proceeds once clear) |
| `DELIVER_PENDING`   | Roadmap ready, about to dispatch DELIVER             | **Cost-check gate:** if `~/.claude/token-budget.md` exists, follow it — calibrate `nw-rigor`, say the wave/agent count out loud before dispatch                 | this skill                         | `DELIVER_RUNNING`                                    |
| `DELIVER_RUNNING`   | DELIVER dispatched                                   | `run_in_background: true`, then arm a `Monitor` per `watch`'s own "nWave / DES specifics" recipe — `STEPS` from `roadmap.json`, commit count as the terminal, never Bash-probe `execution-log.json` (`watch/SKILL.md:375-383`) | `nw-deliver`/`nw-execute` + `watch` | `SHIP_READY` (commit count == `STEPS`) or a check-in per `watch`'s stall criteria |
| `SHIP_READY`        | nWave path: all steps COMMIT/PASS, Phase 7 already pushed one branch (`nw-deliver/SKILL.md:228-230`). Light path: `LIGHT_REVIEW` passed | If `.claude/rep-calibration.jsonl` has a `PENDING` entry for this task, score it first, per "Learning-rep styles" below — the wave path's own equivalent of `CHECK`'s scoring step, since `SHIP_READY` is the first point after the fix where the diff is settled. **Docs check next**: invoke `docs-review` before anything else, unless this run was triaged as `REFACTOR` (no intended behaviour change — nothing for docs to have drifted against). Covers `NO_FEATURE`/`FEATURE_IN_FLIGHT`, `BUG_FIX`, and the light path's `LIGHT_CYCLE` alike, since only `REFACTOR` is excluded. Then decide stacking — see below. On the light path this is just `ship`'s own step 2 draft PR (opened at branch creation) reaching step 10, ready-for-review | `docs-review` (unless `REFACTOR`) then `ship` / `gh-stack` | `SHIPPED`                                            |
| `SHIPPED`           | PR open                                              | `/done` if the session is closing; otherwise loop to `ECOSYSTEM_CHECK` for the next piece of work                                                                | `done`                              | `ECOSYSTEM_CHECK`                                    |

**Stacking, decided 2026-09-07: scope layers in DISTILL, not inside `nw-deliver`.**
`nw-deliver` runs exactly as nwave-ai specifies — no patch, no fork of its commit/push mechanics
(that option was considered and rejected: it needs its own decision record and an upstream
nwave-ai change before any skill here could assume it exists). Instead:

- **Size each layer at `nw-new` time**, not at feature grain. A layer is a roadmap-sized slice —
  "add rule X with its acceptance test," not "the whole feature" — matching `ship/SKILL.md`'s
  existing "name the layers before writing" rule. Run DISTILL and DELIVER exactly as specced for
  each slice; the stacking discipline is entirely in how the roadmap gets scoped up front, not in
  how DELIVER executes.
- **Nothing extra needed for the draft PR** — `ship`'s step 2 now opens one immediately after any
  branch is created, layer or not (`ship/SKILL.md`, generalised 2026-09-07 from a stack-only rule).
  When the slice's DELIVER run reaches all-COMMIT/PASS, `ship`'s step 10 marks that same PR ready
  — never a second one.
- Stack via `gh-stack` (or `ship`'s "Stacked PRs" convention, `ship/SKILL.md:80-96`) across the
  layers; merge bottom-up, `gh stack sync` after any mid-stack change, same as any other stack.

Decision captured: `docs/decisions/DR--20260907--process--spec-ladder-placement.md`. The related
org-device rigor calibration this skill's `DELIVER_PENDING` gate reads from `token-budget.md` is
captured separately in `docs/decisions/DR--20260907--process--nwave-rigor-profile-org-device.md`.

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

**What this does not do yet.** `human-red`, `adversarial-review`, `fault-injection`,
`faded-scaffold`, and `explain-before-reveal` are all named but unbuilt. `adversarial-review` is
the next-easiest — it's a checkpoint at `SHIP_READY`, same shape as this one. The other four need
changes inside `red`/`green`/`refactor` or the wave agents themselves, which this skill does not
reach into by design (see Constraints).

## Constraints

- Do not silently widen "hand off to agents" beyond nWave's own mandatory wave dispatch —
  everything else stays under the Delegation Budget.
- Do not invent a stacking mechanism inside `nw-deliver` — it's vendored, and patching it was
  considered and rejected (`docs/decisions/DR--20260907--process--spec-ladder-placement.md`).
- This skill sequences `nw-new`/`nw-continue`/`nw-bugfix`/`nw-refactor`, the existing mandatory
  wave dispatch, `watch`, `story`/`red`/`green`/`refactor`/`check`, and `ship`/`gh-stack`. One
  deliberate exception to "no new agent": `LIGHT_REVIEW` names `pr-review-toolkit:code-reviewer`
  explicitly, because the light path has no nWave `*-reviewer` gate to inherit and would otherwise
  have no independent check at all. `review/SKILL.md` itself is unchanged and still available for
  a quick manual self-review outside this pipeline — this is `buildy`'s own automated path
  choosing the independent-agent option instead of it.
- **`TRIAGE`'s bar is "obvious."** An ambiguous bug-or-feature or refactor-or-redesign call
  defaults to `NO_FEATURE`/`nw-new` — that's more scrutiny, not less, and matches Inference
  Discipline (don't generalise a routing decision from a thin signal).
- **`ECOSYSTEM_CHECK` is a filesystem fact (`.nwave/` present or not), never a judgment call.**
  Do not reach for the nWave path in a project that hasn't installed it, and do not reach for
  `story`/`red`/`green`/`refactor` in one that has — the two pipelines are not interchangeable by
  preference.
- The light path has no `nw-rigor`/`token-budget.md` cost gate to read — there is no wave
  machinery underneath it to calibrate. If `LIGHT_CYCLE` work is itself delegated to a background
  agent, the Delegation Budget and `watch` still apply on their own terms; this skill does not
  invent a light-path equivalent of `DELIVER_PENDING`.
- **`SHIP_READY`'s docs-review gate excludes only `REFACTOR`.** A refactor has no intended
  behaviour change by definition, so there's nothing for docs to have drifted against. A bug fix
  is included on purpose — fixing behaviour is exactly the kind of change that leaves docs
  describing the old, wrong behaviour, and `docs-review`'s own trigger ("user-facing behaviour,
  wording, or a tracked decision") applies to it as much as to a new feature. The light path is
  included too, for the same reason: it has no `REFACTOR` classification to exempt it, and a
  well-understood small change can still be user-facing.
- **`ID_COLLISION_CHECK` only covers features routed through this skill.** A wave invoked by hand,
  outside `buildy`, isn't checked. The fix belongs in nwave-ai's own DESIGN/DISCUSS allocation
  logic, not here — but that's vendored, generated-projection code we don't control, so the gate
  lives in `buildy` instead (`docs/decisions/DR--20260908--process--cross-worktree-id-collision-check.md`).
- **`REP_STYLE_CHECK` asks once per task, never assumes carry-over.** A style chosen for one task
  is not a standing mode — ask again next time, even in the same session. A default nobody
  re-confirms is the same silent drift the DES `SKIPPED` taxonomy exists to catch elsewhere.
- **`predict-first` never rounds a miss up to spare the moment.** The hit-rate is only worth
  reading later if every entry in `.claude/rep-calibration.jsonl` was scored the same
  way — against the diff, not against how the hypothesis reads.
