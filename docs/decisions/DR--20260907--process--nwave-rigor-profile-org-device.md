---
id: DR--20260907--process--nwave-rigor-profile-org-device
status: accepted
dateCreated: 2026-09-07
domain: process
changelog:
  - date: 2026-09-07
    version: 0.1.0
    note: Initial draft, decided and applied same session
---

# nWave rigor profile for the org-managed device: `standard`, not `lean` or a haiku-agent custom profile

## Context

The org-managed device carries a £1500/month metered token budget, unlike the personal Claude Pro
device (fixed subscription, usage-window-limited). `~/.nwave/global-config.json` had no `rigor` key
set at all. nw-rigor's own default was silently in effect. A device-specific overlay
(`local/work/token-budget.md`) was written to make the calibration explicit, and a rigor profile
needed picking for it.

## Options Considered

### Option 1: `lean` preset

nw-rigor's own `lean` table: `agent_model: haiku`, `reviewer_model: skip`, `review_enabled: false`,
`tdd_phases: [RED, GREEN]` (drops `COMMIT`), `refactor_pass: false`.

- Cheapest on paper.
- **Rejected.** `review_enabled: false` directly contradicts `ENGINEERING-DEFAULTS.md`'s existing
  rule: _"Reviewers always run... never skip a wave's reviewer gate to 'stay lean' — running it
  is the lean choice"_ (verbatim anticipating and forbidding this exact preset). Dropping the
  `COMMIT` TDD phase also risks breaking `nw-deliver`'s own Phase 2 gate ("all steps reach
  `COMMIT`/`PASS`") and `buildy`'s `watch` terminal condition (commit count == `STEPS`). This risk
  was not verified against `nw-deliver`'s gate logic directly.

### Option 2: Custom profile, `agent_model: haiku`, `reviewer_model: haiku`

Keeps `review_enabled: true` (unlike Option 1), but downgrades the _implementer_ model to Haiku.

- **Rejected.** `agent_model` drives the crafter/architect/acceptance-designer roles: the
  highest-stakes reasoning in the pipeline. A weaker implementer raises the odds the
  (already-mandatory) reviewer flags something, triggering rework, which costs more net tokens
  than doing it right once, following the same logic `ENGINEERING-DEFAULTS.md` already uses to
  justify mandatory reviewers. No spend data existed to justify this as a necessary cut. This was
  invented cost pressure.

### Option 3: `standard` preset, unmodified

nw-rigor's own recommended default: `agent_model: sonnet`, `reviewer_model: haiku`,
`review_enabled: true`, `tdd_phases: [RED, GREEN, COMMIT]`, `refactor_pass: true`,
`mutation_enabled: false`.

- Already the "strong on implementation, cheap on review" split this device actually needs.
- No upstream change, no custom profile to maintain: nwave-ai's own recommended default.

## Decision

**Option 3.** Set globally in `~/.nwave/global-config.json` under `rigor`, and stated explicitly in
`local/work/token-budget.md` so an unset value never again silently inherits nwave-ai's own
default. The real cost lever this device needed was never in doubt (reviewer model, already
Haiku by nwave-ai's own default). The two rejected options were solving a problem that either
conflicted with an existing mandatory rule or was not yet evidenced.

## Exceptions

If real per-token spend data becomes visible (still an open question in `token-budget.md`) and
shows `standard` genuinely threatens the £1500/month cap, revisit. That revisit requires the
evidence in hand; it does not license preemptively downgrading `agent_model` again.
