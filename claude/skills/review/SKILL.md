---
name: review
description: Self-review staged changes or a full branch diff to catch issues before committing or pushing. Use before committing to review staged changes, or before pushing to review the full branch.
---

Review code changes for issues a reviewer would catch. $ARGUMENTS

Detect the scope automatically:

- If there are **staged changes**: review pre-commit (staged diff only)
- If there are **unstaged commits on branch**: review pre-push (full branch diff vs main)
- If $ARGUMENTS specifies `commit` or `push`: use that scope explicitly

## Step 1 — Get the diff

**Pre-commit (staged):**

```bash
git diff --staged
git diff --staged --stat
```

**Pre-push (branch):**

```bash
git diff main...HEAD
git diff main...HEAD --stat
git log main...HEAD --oneline
```

## Step 2 — Review lenses

Assess each in turn. Only flag genuine issues — don't nitpick style that Prettier/ESLint already enforces.

### Code quality

- Names communicate intent clearly
- Functions do one thing
- No unnecessary complexity or indirection
- No dead code, commented-out blocks, or debug statements left in
- Readability over cleverness

### Design fit

- Consistent with existing patterns and architecture in the repo
- Right level of abstraction — not over-engineered, not under-engineered
- No premature abstractions introduced for a single use case
- Dependencies added only where clearly justified

### Security

- No secrets, tokens, or credentials in code or comments
- Input validated at system boundaries (user input, external APIs)
- No obvious injection risks (SQL, shell, XSS)
- No new attack surface introduced without justification

### Test coverage

- New behaviour has tests
- Tests are meaningful — they'd catch a real regression, not just pad coverage
- No implementation detail tested when behaviour can be tested instead
- Edge cases and error paths covered where they matter

### Commit hygiene (pre-commit)

- Is this change focused enough for a single conventional commit?
- If not: suggest how to split it
- Suggest a conventional commit message: `type(scope): description`

### Branch coherence (pre-push)

- Does the commit history tell a clear, logical story?
- Any commits that should be squashed or reordered before the MR?
- Is the branch small enough to review effectively? (>400 lines of change is a signal)

## Step 3 — Report

Structure findings by severity:

**🚫 Blocking** — must fix before commit/push (security issues, broken logic, missing tests for new behaviour)

**⚠️ Suggestion** — worth fixing now; a reviewer will likely raise it (design issues, readability, test quality)

**💬 Nit** — minor; fine to ignore or fix in a follow-up (naming, small style issues not caught by linter)

If no issues: "Ready to commit/push. Suggested commit message: `...`"

## Constraints

- Do not fix issues automatically — report and let Dan decide
- Do not flag issues already caught by lint/typecheck — assume `/check` handles those
- If a security issue is found, explain the risk before suggesting a fix
- Keep the report concise — group related issues, don't repeat the diff back
