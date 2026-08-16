---
name: story
description: Scaffold a user story with who+what+why, acceptance criteria, and priority rationale. Use when planning a new feature or capability for a backlog.
---

Draft a user story for the following: $ARGUMENTS

## Instructions

Produce a well-formed user story with:

### Story statement

**As a** [who — specific role or persona, not "user"]
**I want** [what — the capability or action]
**So that** [why — the outcome or value delivered]

### Context

1–3 sentences of background. What problem does this solve? What's the current state?

### Acceptance criteria

Written as testable conditions using "Given / When / Then" or plain checkbox format.
Be specific — vague AC leads to scope creep and failed demos.
Cover: happy path, key edge cases, explicit out-of-scope items.

### Technical notes (if applicable)

Known constraints, dependencies, or implementation considerations worth flagging early.
Do not design the solution — just surface risks or assumptions that affect scope.

### Priority rationale

Is there technical risk here that should move this earlier in the backlog?
What's the cost of doing this late vs. early?

### Size signal

Small / Medium / Large — based on unknowns and complexity, not just line count.
Flag if this should be split before starting.
