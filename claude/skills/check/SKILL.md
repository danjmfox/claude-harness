---
name: check
description: Run the full quality gate (lint, typecheck, tests, coverage) and summarise results. Use before pushing or after making significant changes to catch issues locally before CI does.
---

Run the full quality gate for the current project and summarise the results.

## Instructions

1. **Detect the project type** by reading the root directory — look for `.mise.toml`, `package.json`,
   `Makefile`, `.gitlab-ci.yml` etc.

2. **Identify the quality gate commands** in priority order:
   - If `.mise.toml` has a `check` task: `mise run check`
   - Otherwise run individually: lint → typecheck → test → coverage
   - Check for `trunk check` configuration

3. **Run the commands** and capture output.

4. **Summarise results** clearly:

   | Check     | Status  | Notes              |
   | --------- | ------- | ------------------ |
   | Lint      | ✅ / ❌ | ...                |
   | Typecheck | ✅ / ❌ | ...                |
   | Tests     | ✅ / ❌ | N passed, M failed |
   | Coverage  | ✅ / ❌ | X% (threshold: Y%) |
   | Trunk     | ✅ / ❌ | ...                |

5. **For any failures:** show the relevant error output and suggest the most likely fix.

6. **If coverage is below threshold:** identify the lowest-covered files and suggest where
   to focus next.

## Constraints

- Do not fix failures automatically — report and recommend
- If a command is missing or not configured, note it as a gap rather than skipping silently
