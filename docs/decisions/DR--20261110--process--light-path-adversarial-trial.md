---
id: DR--20261110--process--light-path-adversarial-trial
status: proposed
dateCreated: 2026-11-10
domain: process
changelog:
  - date: 2026-11-10
    version: 0.1.0
    note: Initial draft. Three PROPOSED changes to buildy's light path, trial plan, no pilot run yet. Owner chose general-purpose agents and no nWave dependency on the light path
---

# Trial three light-path changes in buildy: an adversarial checkpoint, independent acceptance tests, and a concurrent-work state

Labels used below: VERIFIED (observed in a source or a run this session), PROPOSED (a design choice or inference, untested), NOT KNOWN (no evidence found).

## Context

`buildy`'s light path (`story`, `red`, `green`, `refactor`, `check`, `LIGHT_REVIEW`, `docs-review`, `ship`) runs in projects that have not enabled nWave. This record was prompted by a comparison with `swarm-of-experts-demo`, a template repository of Claude Code subagents (read only), and with concurrent worktrees in `google-calendar-adhd-helper` (read only).

**Opportunity Statement.** Review and nWave's source-blind EXAMINE confirm that agreed promises were kept. Nothing in the light path tries to break the delivered change against a source of truth that is independent of the artefact. On the light path the author and the unit tests also share one head: the main session writes both. The opportunity is a checkpoint whose job is to refute, with a measure of whether it finds anything the existing gates accepted.

**Evidence, and its limits.**

- VERIFIED: the swarm's `sniper` agent attacks only after a `validator` PASS, receives neither the builder's reasoning nor the validator's tests, and reads `docs/target-profile.md` first. It blocks without one.
- VERIFIED: in one recorded run (`examples/01-word-count-cli/sample-run/team/outbox/sniper.md`) the sniper returned 5 findings after a validator PASS (2 spec gaps, 3 defects in a research note), then 2 more on a re-attack. That is one run. It is not a rate.
- NOT KNOWN: the swarm README says "self-review is measured to make results worse". A search of `docs/research/sources.md` found no source for it. Treat the claim as PROPOSED, not as a reason for this record.
- VERIFIED: nWave's `nw-user-examiner` classifies an unmet verdict as `oracle_gap` when the oracle did not check what was promised, and `nw-nwdes` says a rework repairing an examine finding adds it as an oracle test observed RED before the repair.
- VERIFIED: the calendar project has three lingering worktrees (`confident-mahavira-519a6a`, `extension-bookmarklet-alignment-326930`, `funny-easley-e675b3`) whose commits (`a9fa4e0`, `889f5c9`, `4c9fd35`) are all contained in `main`.
- NOT KNOWN: whether that is typical. It is one project.
- VERIFIED: no suite under `tests/` references `buildy`, so no existing bash test covers these edits.

## Options Considered

### Option 1: Do nothing

- No cost, no new agent.
- Leaves the friction unmeasured. The light path has no external check at all beyond `LIGHT_REVIEW`.

### Option 2: Trial the three changes, one `buildy` diff each, labelled PROPOSED

- Each change can be kept or dropped alone, and each has its own measure (see Trial plan).
- Adds states and a second and third agent dispatch to a skill that is meant to be glue.

### Option 3: Port the swarm's full gated pipeline

- Closest to the source.
- Blindness there is hook-enforced. Here it would be prose only, and the pipeline duplicates nWave's own roles. Rejected as the larger Cognitive Load Tax.

## Decision

**Option 2**, pending the owner's approval of this record. The three changes:

| Change                                                    | Opportunity                                                                            | Status   |
| --------------------------------------------------------- | -------------------------------------------------------------------------------------- | -------- |
| (a) `ADVERSARIAL_CHECK`, opt-in state before `SHIP_READY` | Something tries to break the change against an independent source of truth             | PROPOSED |
| (b) Independent acceptance tests at story time            | A frozen oracle the author cannot edit, and acceptance-level capture on the light path | PROPOSED |
| (c) `CONCURRENT_WORK` state                               | Parallel lanes without a board file, and lane cleanup after merge                      | PROPOSED |

**Trial plan.** Revisit after the earlier of five light-path tasks run with the change on, or 2026-12-31.

| Change | How tested                                                                                                                                                                                                 | Measure                                                                                                                                                        | Revisit                                                                                                                              |
| ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| (a)    | Pilot on tasks with an external surface (CLI, parser, API) and a hand-written `docs/target-profile.md`. Record each run: findings the check made, and for each whether `LIGHT_REVIEW` had accepted past it | **Yield**: findings the check made that review had accepted past, per run. Tokens and minutes per run are recorded beside it                                   | Drop if yield is 0 over three eligible runs. Keep as opt-in if at least one finding was an `oracle_gap` repaired by a RED-first test |
| (b)    | Pilot on tasks that go through `story`. Record: criteria turned into tests, how many were RED at first run, and how many times the main session asked to edit a frozen test                                | RED-first rate, and the count of acceptance tests that would fail if the new behaviour were deleted (the global "pinned by its own acceptance-level test" bar) | Drop if the frozen tests are rewritten by the main session in most runs, or if unit tests already pin every criterion                |
| (c)    | Pilot when the owner next asks for concurrent work. Record: lanes opened, lanes removed after merge, merge conflicts found at the trunk-merge step, wall time against serial                               | Lingering worktrees after merge (target 0), and conflicts caught before ready rather than after                                                                | Drop if no concurrent request arrives within the window. NOT KNOWN: a rate, since the calendar project is one data point             |

Verification of the edits themselves: the three diffs are prose in `SKILL.md`. Each is checked by a read-through against the state table (every new state has a trigger and a next state, and `SHIP_READY` is reachable from each), not by a bash test. A passing check on arrival would be unverified, so the first pilot run is the real test.

## Exceptions

- (a) is a second agent exception beside `pr-review-toolkit:code-reviewer`. In the swarm, blindness is enforced by hooks. Here it would be enforced only by what the dispatch prompt withholds, so a leak is possible and would not be detected. PROPOSED mitigation: the prompt names the paths the agent must not open, and the pilot log notes any that it did.
- (a) depends on a human-written `docs/target-profile.md`. Nothing generates it. A project without one skips the state, which is the common case.
- (b) adds a third dispatch, so it counts against the same cost check as (a). Both dispatches use `general-purpose` agents on Opus, and the light path uses no nWave role. A dedicated agent file with tool restrictions would enforce more than prompt text and is deferred until the yield measure justifies its install cost.
- Revisit this record early if an adversarial finding the check made turns out to be a false positive that cost a fix cycle.
