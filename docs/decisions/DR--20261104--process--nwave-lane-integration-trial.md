---
id: DR--20261104--process--nwave-lane-integration-trial
status: proposed
dateCreated: 2026-11-04
domain: process
changelog:
  - date: 2026-11-04
    version: 0.1.0
    note: Initial draft, written when buildy was reworked for nWave 4
---

# Trial nWave 4's own lane integration instead of PRs, and replace the 7-wave sequence with its three routes

## Context

This harness assumed nWave 3's process: seven waves walked in order (DISCOVER, DIVERGE, DISCUSS, DESIGN, DEVOPS, DISTILL, DELIVER), then a pull request per branch, with stacked branches for layered work. nWave 4.1.0 changed both halves.

Process: `nw-auto` offers three routes (spine waves, host-led nwdes steps, working directly), chosen by what must survive the session and what a late refusal would cost. Waves are entered when their durable authority is missing, not walked in sequence.

Shipping: nWave 4 has no pull-request or push step. `nwdes lane integrate` fast-forwards local trunk to the reviewed candidate and removes the lane, and CI gates the push of trunk rather than the integration (`nw-throughput`). This conflicts with this repo's Git Discipline rule "never commit to `main`" and with its PR-per-branch lifecycle. A lane opens at trunk, so it cannot stack on an unmerged earlier lane.

## Options Considered

### Option 1: Keep PRs from the lane branch

- Preserves PR review and the existing `ship` flow.
- Skips `lane integrate`, so each lane's worktree and branch linger until removed by hand, and the removal path is untested.
- Departs from how nWave 4 expects a Request to end.

### Option 2: Use nWave's lane integration (trial)

- Follows the tool as designed: `lane compose`, `lane integrate`, then push trunk after CI.
- Trunk moves before any PR review, so review happens inside the Request (final whole-candidate review and EXAMINE) instead.
- Layers become sequential Requests, each integrated before the next lane opens.

## Decision

**Option 2, as a trial.** The nWave path in `buildy` runs the lane verbs as specified, asks before pushing trunk, and treats the 7-wave sequence as one of three routes. The light path (no nWave) keeps `ship`'s PR flow. This is a tracked exception to "never commit to `main`".

## Exceptions

Revisit when any of these happens: a push of trunk is rejected by branch protection; a defect reaches trunk that PR review would have caught; a lane or worktree lingers after `integrate`. Record each occurrence here. The stacking decision `DR--20260907--process--spec-ladder-placement` (layers scoped in DISTILL, stacked PRs) rests on nWave 3 behaviour and needs its own revisit.
