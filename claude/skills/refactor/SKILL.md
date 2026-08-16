---
name: refactor
description: Improve code quality without changing behaviour while keeping tests green. Use after /green when the implementation works but could be cleaner or clearer.
---

Improve the code quality without changing behaviour. Tests must remain green throughout.

## Instructions

1. Read the current implementation and its tests
2. Identify opportunities to improve — but only act on clear wins:
   - Duplicated logic that can be extracted cleanly
   - Names that don't communicate intent
   - Functions doing more than one thing
   - Unnecessary complexity or indirection
3. Do not change what the code does — only how it's expressed
4. Do not add new behaviour, error handling, or features
5. Do not change test code unless test names or structure are genuinely misleading
6. After each change, confirm the tests would still pass

## Output

- The refactored code
- A brief list of what changed and why (one line each)
- Explicit statement of what was considered but left alone, and why

## Constraints

- Readability over cleverness
- If in doubt, leave it — premature abstraction is worse than duplication
- Small, safe steps — not a full rewrite
