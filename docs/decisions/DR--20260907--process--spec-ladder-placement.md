---
id: DR--20260907--process--spec-ladder-placement
status: accepted
dateCreated: 2026-09-07
domain: process
changelog:
  - date: 2026-09-07
    version: 0.1.0
    note: Initial draft, decided and applied same session
---

# Spec Ladder placement: scope layers in DISTILL, not `nw-deliver`'s commit mechanics

## Context

A reference pattern ("Spec Ladder") describes bridging outside-in TDD's red-until-done discipline
with stacked PRs' green-per-layer requirement via skip/unskip: a spec layer authors an acceptance
test skipped plus a stub, an impl layer unskips it and wires it in, reviewers routed by layer type.
We wanted this for `buildy`'s DELIVER stage, but `nw-deliver` (nwave-ai, vendored) commits once per
roadmap step and pushes only once, at its own Phase 7. It does not branch or open a PR per step.
Somewhere, a placement had to be chosen for where the layering discipline actually lives.

## Options Considered

### Option 1: Per-feature stacking via `gh-stack`

Each layer is its own full `nw-new` feature, based on the branch below it, stacked via `gh-stack`.

- Buildable immediately, no upstream dependency.
- Does not touch the actual tension the pattern solves: each feature is fully green before
  joining the stack, so no acceptance test ever sits red-but-dormant across layers. This is a
  problem `gh-stack` already solved before the Spec Ladder pattern existed.
- Most expensive option: full DISCUSS→DESIGN→DISTILL overhead repeats per layer.

### Option 2: Patch `nw-deliver`'s own commit/push mechanics

Change `nw-deliver` so each roadmap step becomes its own branch/PR instead of one branch with a
single push at Phase 7.

- Implements the pattern as designed, at the intended grain: DISTILL already authors the
  acceptance tests, DELIVER already implements against them. This only exposes an existing
  conceptual seam as a git seam.
- `nw-deliver` is nwave-ai's own vendored package, not this repo's code. Patching it is an ongoing
  maintenance tax against a package with a track record of breaking changes (v3.22.0's `--task-id`
  CLI break, silent file-set drift between tags) and needs its own decision record plus probably
  an upstream issue before any local skill could assume the behaviour exists.

### Option 3: Scope DISTILL's roadmap into layer-sized `nw-new` slices

Size each layer at `nw-new` time to a roadmap-sized slice, for example "add rule X with its
acceptance test" instead of "the whole feature." Run DISTILL and DELIVER exactly as nwave-ai specifies for each slice; the
decomposition lives entirely in how the roadmap is scoped up front. Stack the slices via
`gh-stack`/`ship`'s existing convention.

- Gets real skip/unskip-flavoured decomposition: an earlier slice's acceptance test can
  genuinely sit authored-but-unimplemented until the next slice lands, using only tooling that
  exists today.
- Cheaper than Option 1 (no repeated DISCUSS/DESIGN overhead) and carries no upstream dependency
  like Option 2.
- Cost is discipline: layer boundaries must be decided in DISTILL up front, matching `ship`'s
  existing "name the layers before writing" rule for stacked PRs generally.

## Decision

**Option 3.** Layer sizing happens in DISTILL's roadmap scoping; `nw-deliver` runs unmodified.
As a direct consequence, `ship`'s draft-PR step was generalised (not scoped to recognised stack
layers only): every branch now opens a draft PR immediately after creation (`ship` step 2, base
declared from the start), converted to ready for review once its own tests are green (`ship` step
10). This gives `gh-stack` something to track from commit one on any layer, without requiring the
decision of "will this stack?" to be made before it's knowable.

## Exceptions

Revisit Option 2 if Option 3 proves insufficient in practice. That revisit goes through its own
decision record and, likely, an upstream nwave-ai proposal. Do not fork or patch `nw-deliver` locally as a
shortcut around that.
