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

## Phase 2 — Save the story

Save the drafted story as markdown, the same way `/adr` saves a decision record — otherwise this
scoping work exists only in chat and is gone once the conversation ends.

1. **Find the stories directory.** Look for an existing one — commonly `docs/stories/` or
   `docs/backlog/`. If none exists, create `docs/stories/`, or ask where the user keeps them.
2. **Derive a slug** from the story's **I want** clause (kebab-case, no dates — stories aren't
   versioned records) and write the file as `<slug>.md`.
3. **Confirm**: "Story `<slug>` saved to `<path>`. Update it in place as scope changes; there's no
   separate status field to advance."
