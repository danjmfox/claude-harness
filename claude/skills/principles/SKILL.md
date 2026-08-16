---
name: principles
description: Apply engineering principles to a decision or question, surface tensions, and reason to a recommendation. Use when facing a trade-off or design choice to get principle-grounded reasoning before or instead of a full ADR.
---

Apply my engineering principles to the following decision or question: $ARGUMENTS

## Instructions

1. **Identify the relevant principles** from my PRINCIPLES.md that bear on this question.
   Not all principles apply to every decision — be selective.

2. **Surface any tensions** between principles. Where two principles pull in different directions,
   name the trade-off explicitly rather than ignoring it.

3. **Reason to a recommendation** grounded in the principles. Show the reasoning, don't just
   state the conclusion.

4. **Flag if an ADR is warranted** — if this decision is significant enough to capture formally,
   say so and suggest a domain and slug.

## Output

- Relevant principles (2–4 max, with one sentence on why each applies)
- Tension(s) if any
- Recommended approach with rationale
- ADR trigger: yes/no, and if yes, a suggested domain and slug — run `/adr` to draft and save the record
