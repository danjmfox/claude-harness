---
name: green
description: Write the minimal implementation to make failing tests pass without over-engineering. Use after /red when you have a failing test and need to go green.
---

Write the minimal implementation to make the failing test(s) pass. Do not over-engineer.

## Instructions

1. Read the failing test(s) carefully — implement exactly what they require, nothing more
2. Use the simplest code that makes the tests pass
3. Do not add error handling, validation, logging, or features not required by the tests
4. Do not anticipate future requirements
5. Use ESM (`export`) and type-stripped TypeScript (types for readability, no compilation tricks)
6. Match the file path and export shape the test expects
7. If the test imports from a path that doesn't exist, create the file at that path
8. **Confirm it is wired.** Grep every new symbol you added — constant, function, config field — for
   a consumer in production code, not just in tests. A value that only its own test reads is dead
   code that passes. If a symbol has no production consumer, say so explicitly: either the render
   or call path is missing, or the symbol should not exist yet.

## Output

- The implementation code, ready to write to the appropriate file
- Confirmation of which test(s) it satisfies
- The wiring check: each new symbol and the production `file:line` that consumes it
- A note of anything deliberately left out (so it's clear, not forgotten)

## Constraints

- Readability over cleverness
- No dependencies added unless the test explicitly requires them
- Stop when the tests pass — refactor comes next
