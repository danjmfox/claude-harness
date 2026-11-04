---
id: DR--20261027--process--risk-first-ordering
status: proposed
dateCreated: 2026-10-27
domain: process
changelog:
  - date: 2026-10-27
    version: 0.1.0
    note: Initial draft. Not applied; no standing order or skill has changed.
---

# Risk-first ordering: the first slice retires the riskiest assumption against a real dependency

## Context

Feature work here runs through nWave, a seven-wave method: DISCOVER, DIVERGE, DISCUSS, DESIGN, DEVOPS, DISTILL, DELIVER. A "walking skeleton" is the first thin slice that connects every architectural layer. A "real dependency" is the actual external system or data a feature relies on, for example a live Jira instance. A "fake" is a test double or fixture file standing in for it.

`PRINCIPLES.md` section 5 (Shift-Left and Technical Risk) already says to tackle hard, high-assumption work first. `ENGINEERING-DEFAULTS.md` says a skeleton proves architecture risk and an MVP proves value risk. Both are guidance to the agent. Nothing in the `buildy` skill or in nWave's wave order makes the riskiest assumption the first thing tested, and `nw-spike`, which names external integrations as its trigger, is optional.

The failure this record responds to happened on 2026-10-27 in the `pod-capacity-forecast` project, a TypeScript tool that computes capacity splits from Jira. DISCUSS, DESIGN and DISTILL ran with Jira replaced by a fixture adapter. At the time of review the source tree was 104 lines, against about 3,260 lines of acceptance tests, 950 lines of fixtures and 2,750 lines of Markdown and YAML, and the tool produced no output. Its own feature document records that a fixture-only skeleton cannot meet its production-data criterion. The unknowns that could invalidate the design (how the Jira Team field behaves across projects, changelog-derived cycle time, agreement with the existing Python tool's numbers) were untouched. The survey that preceded the work also placed the comparison with the existing tool in DISTILL, after specification.

Without a decision, the principle stays advisory and the same sequence will recur: specification grows faster than evidence.

## Options Considered

### Option 1: Keep the principle as guidance only

Status quo. No cost, and it already exists. It failed on the project above while the principle was loaded, because it depends on the agent noticing the pattern mid-wave.

### Option 2: A mandatory spike wave before every feature

Every feature starts with a timeboxed `nw-spike` probe. This is strong on risk and heavy on cost: small or mechanical features pay for a ceremony that has nothing to retire. It also conflicts with the latitude clause (match machinery to consequence).

### Option 3: A short ranked risk list before DISCUSS, and a real-dependency first slice

Before DISCUSS the agent proposes three to five assumptions that would invalidate the feature if false. Each gets a one-line statement, the impact if it is false, how uncertain it is, and the cheapest real test. The architect confirms the ranking. The first slice delivered, or a spike, must exercise the top-ranked assumption against the real dependency, and a fake of that dependency does not count. Fakes remain acceptable for later slices. Cost scales with the number of real unknowns, so a feature with none needs a one-line list.

### Option 4: A hook that blocks work until the risk list exists

Like the existing RED gate hook, a script checks a fact. Presence of a risk list is checkable; whether it names the right risks is not. It would add machinery before the practice has been tried by hand, and could produce pro forma lists.

## Decision

Option 3. Four properties are deliberate.

- **A ranked list, confirmed by the architect.** The agent drafts it and the architect ratifies the order, because deciding when a spike is needed belongs to the architect.
- **Real, not simulated.** A slice retires an assumption only when it runs against the real dependency or against the existing system used as an oracle. The evidence (command output or a data run) is recorded in the feature's wave artefacts, in line with Verification Before Claiming Success.
- **Open risks stay visible.** If the real dependency cannot be reached (credentials, access, a sandbox limit), the risk stays listed as open. Work on later slices may proceed on fakes, but the first slice is not called a walking skeleton until the risk is retired.
- **Proportionate.** A feature with no real unknown records that in one line and proceeds.

Trade-offs accepted: some up-front thinking per feature; a judgement-based ranking that can be wrong; the first slice may be throwaway code (promotable via `nw-spike`); and a human may need to run the real check where an agent session cannot.

Out of scope here, to be decided separately: wiring a risk step into `buildy`, wording of the standing orders, and any measure of artefact size against working behaviour. That measure is untested against real repositories and is not enshrined by this record.

## Exceptions

- Mechanical or trivial changes, where the latitude clause applies: run directly, keep the test that pins the behaviour.
- Features whose only dependencies are already proven in the same project.
- Work whose real dependency is permanently unavailable. State that fact and what the fake leaves unproven, instead of calling the result validated.

Revisit this decision if two consecutive features produce pro forma risk lists, if the recorded evidence of a retired risk repeatedly fails to reach the wave artefacts, or if the practice proves heavier than the rework it prevents.
