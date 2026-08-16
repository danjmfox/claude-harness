---
name: adr
description: Think through, draft, and save a Decision Record as plain markdown. Use when facing a significant architectural, tooling, or process decision that needs explicit reasoning and future context.
---

Help me think through and draft a Decision Record for the following topic: $ARGUMENTS

## Process

Work through this in order. Don't skip steps.

### 1. Problem statement

Articulate the problem or question that needs a decision. What is the pressure forcing a choice?
What happens if we don't decide?

### 2. Principles in play

From my engineering principles, identify which ones are relevant and how they create tension or
point toward a solution.

### 3. Options considered

List at least 2–3 realistic options. For each:

- What it is
- Key advantages
- Key disadvantages / risks
- Fit with relevant principles

### 4. Recommendation

Propose the best option with a short rationale grounded in the principles identified above.
Flag any significant trade-offs being accepted.

### 5. Exceptions

Are there contexts where a different choice would be warranted? What would trigger revisiting
this decision?

## Output format

Produce a draft Decision Record in this structure, ready to save as a markdown file:

```markdown
---
id: DR--YYYYMMDD--<domain>--<slug>
status: proposed
dateCreated: YYYY-MM-DD
domain: <domain>
changelog:
  - date: YYYY-MM-DD
    version: 0.1.0
    note: Initial draft
---

# <Title>

## Context

<problem statement>

## Options Considered

### Option 1: <name>

...

### Option 2: <name>

...

## Decision

<chosen option and rationale>

## Exceptions

<when this decision might not apply>
```

Use today's date. Suggest a domain and slug based on the topic.

## Phase 2 — Save the record

Save the drafted markdown as a decision record in the project.

1. **Find the decisions directory.** Look for an existing one — commonly
   `docs/decisions/`, `doc/decisions/`, or `docs/adr/`. If none exists, create
   `docs/decisions/`, or ask where the user keeps decision records.

2. **Write the file** as `<id>.md`, taking the filename from the `id`
   frontmatter value (e.g. `DR--20260803--tooling--drop-drctl.md`). Preserve
   the frontmatter; the body is the drafted content.

3. **Confirm:** "Decision record `<id>` saved to `<path>` at status
   `proposed`. Advance the `status` frontmatter to `accepted` and add a
   changelog entry once the decision is ratified."

For significant cross-cutting decisions — a type contract, a cross-package
interface, or engine behaviour — raise the record through the nWave
DISCUSS/DESIGN waves instead of saving a standalone file, so it lands in the
wave artifacts that carry current truth.
