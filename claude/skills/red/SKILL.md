---
name: red
description: Write a failing Vitest test for a described behaviour without any implementation. Use at the start of a TDD cycle when you have a behaviour to specify but no implementation yet.
---

Write a failing test for the behaviour described below. Do not write any implementation.

**Behaviour to test:** $ARGUMENTS

## Instructions

1. Identify the unit under test — function, module, class, or HTTP route
2. Write the test in Vitest using `describe` / `it` / `expect`
3. Use TypeScript with ESM imports (`import ... from '...'`)
4. Test only the described behaviour — one concern per test
5. The test MUST fail because the implementation does not yet exist or is incomplete
6. If the unit under test does not exist yet, import it as if it will exist at the natural path
7. Name the test precisely: it should read as a specification ("it returns 400 when email is invalid")
8. Do not add happy-path or edge-case tests beyond what was asked — that comes later

## Output

- The test code, ready to paste or write to the appropriate `*.test.ts` file
- One sentence confirming why it will fail (missing export, unmet assertion, etc.)
- The `it` description phrased as a specification statement
