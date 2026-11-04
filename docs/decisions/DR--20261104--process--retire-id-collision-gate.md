---
id: DR--20261104--process--retire-id-collision-gate
status: proposed
dateCreated: 2026-11-04
domain: process
changelog:
  - date: 2026-11-04
    version: 0.1.0
    note: Initial draft, written during the buildy rework for nWave 4
---

# Retire buildy's ID collision gate: nWave 4 renumbers colliding ADRs itself

## Context

`DR--20260908--process--cross-worktree-id-collision-check` (cross-worktree ID collision check, a `buildy` pre-dispatch gate) added a state, `ID_COLLISION_CHECK`, that scanned sibling git worktrees before the DESIGN or DISCUSS wave allocated the next ADR number or story ID (`US-N`). It existed because nWave 3 allocated numbers by globbing only the calling worktree, so two worktrees from one commit allocated the same number. That record named one condition for revisiting: "if nwave-ai's actual contribution path becomes clear."

nWave 4.1.0 changed the situation without a contribution path. `nwdes lane rekey` renumbers a lane-added ADR "using a number free on both sides", and `nwdes lane compose` merges trunk into the lane before integration. Story IDs have no equivalent in v4.1.0: a search of the `v4.1.0` tag found no allocation or collision handling for them. The `buildy` skill is being reworked for the 4.x command set, and the gate's wave-based `IN_WAVE` state no longer exists there.

## Options Considered

### Option 1: Retire the gate and rely on `nwdes lane rekey`

- Removes a state that guards a problem nWave now handles for ADRs.
- Leaves story IDs unguarded, and the v4.1.0 check was a source search, not a run.

### Option 2: Keep the gate for story IDs only

- Guards the one case v4.1.0 does not visibly cover.
- Keeps a check against a failure mode that has not been observed in 4.x, and attaches it to a state (`IN_WAVE`) that no longer exists.

### Option 3: Keep the gate unchanged

- No new risk.
- Duplicates `lane rekey` for ADRs and is written against nWave 3's wave sequence.

## Decision

**Option 1.** Remove `ID_COLLISION_CHECK` from `buildy`. When two lanes both run DISCUSS, check sibling worktrees for `US-N` collisions by hand until a 4.x run shows whether the gap is real. The `buildy` constraints list says so.

## Exceptions

Revisit this record if a story ID collision occurs under nWave 4, or if `lane rekey` is observed not to cover ADRs written outside a lane. Either would justify restoring a gate, through its own decision record. This record does not touch the shipping and stacking questions raised by the same rework; those are open and tracked in `claude/skills/buildy/SKILL.md` under "Shipping, provisional".
