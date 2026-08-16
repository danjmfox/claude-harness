---
name: survey
description: Assess a codebase before making any changes. Covers purpose, coherence, complexity, currency, idiomatic use, tooling, module structure, and consistency between code and docs. Surfaces existing plans for future development. Use at the start of a chat to orient before touching anything.
---

Conduct a structured assessment of the current repository. $ARGUMENTS

Do not suggest changes yet — this is a read-only orientation pass. The goal is a clear, honest picture of what we're working with.

## Step 1 — Gather signals

Read broadly before forming opinions. In parallel where possible:

- Root files: `README.md`, `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml`, `CHANGELOG.md`, `.mise.toml`, `Makefile`, `docker-compose.yml`
- CI/CD: `.github/workflows/`, `.gitlab-ci.yml`, `.travis.yml`
- Config: `.eslintrc*`, `tsconfig.json`, `trunk.yaml`, `vitest.config.*`, `prettier.config.*`
- Docs: `docs/`, `ADR/`, `decision-records/`, any `*.md` beyond the root
- Plans: `.claude/task_plan.md`, `ROADMAP.md`, `TODO.md`, open issues references in code comments
- Source structure: top-level directories, module boundaries, test layout
- Recent history: `git log --oneline -20`, `git branch -a`
- Dependencies: check for outdated runtimes, deprecated packages, known-insecure versions

## Step 2 — Assess each dimension

Evaluate each lens. Be honest and specific — note both strengths and weaknesses.

### Purpose
Is the project's purpose clearly stated? Does the README explain who it's for, what it does, and how to get started? Does the code match that description?

### Overall coherence
Does the codebase feel like a unified thing, or a patchwork? Are naming conventions, folder structure, and architecture consistent? Does the code tell a coherent story?

### Complexity
Is the complexity appropriate for the problem? Look for: unnecessary abstraction layers, deeply nested logic, large files, circular dependencies, god objects/modules, config sprawl. Note any areas that are clearly harder to understand than they need to be.

### Currency
How current is the stack?
- Runtime versions (Node, Python, Go, etc.) vs. current LTS/stable
- Framework and major dependency versions — significantly behind?
- Last meaningful commit — is this actively maintained or quietly stale?
- CI/CD approach — modern, legacy, or absent?

### Relevance
Are there dead areas? Look for: unused dependencies (`depcheck` signals, obvious orphans), commented-out code blocks, unreferenced files, stale branches, features mentioned in docs but absent from code.

### Idiomatic use
Does the code use the language and framework the way they're meant to be used? Flag: reinventing built-ins, fighting the framework, outdated patterns for the current version (e.g., class components in a modern React codebase, callbacks where async/await is idiomatic).

### Contemporary approach
Beyond idiom — does the overall approach reflect current thinking? Consider: architectural patterns, state management, API design, auth, observability, error handling strategy.

### Tools
Assess the toolchain: package manager, task runner, linter, formatter, test framework, CI provider. Are they well-configured? Are there obvious gaps (no linter, no tests, no CI)?

### Module structure
Are module/package boundaries clear and sensible? Is there a coherent separation of concerns? Any obvious coupling that should be decoupled, or splits that add friction without benefit?

### Consistency — code and documentation
Does the code match what the docs say? Are naming, patterns, and conventions applied consistently across the codebase, or are there seams where different eras or contributors diverge? Is the test style consistent?

### Future plans
Surface any signals of intended direction:
- `.claude/task_plan.md` or `.claude/` files
- `ROADMAP.md`, `TODO.md`, `CHANGELOG.md` (Unreleased section)
- TODO/FIXME/HACK comments in source (sample — don't list exhaustively)
- Open decision records or RFCs
- Long-lived branches with unreleased work

## Step 3 — Summarise

Present findings as a structured report. Lead with a one-paragraph overall impression, then cover each dimension.

Use this rating for each dimension: **Strong** / **Adequate** / **Weak** / **Absent**

```
## Survey: <repo name>

<One paragraph: honest overall impression — purpose, condition, main concerns>

| Dimension          | Rating   | Notes |
| ------------------ | -------- | ----- |
| Purpose            |          |       |
| Coherence          |          |       |
| Complexity         |          |       |
| Currency           |          |       |
| Relevance          |          |       |
| Idiomatic use      |          |       |
| Contemporary       |          |       |
| Tools              |          |       |
| Module structure   |          |       |
| Consistency        |          |       |

## Key strengths
- <what's working well>

## Key concerns
- <what needs attention — be specific, not generic>

## Future plans detected
- <any roadmap signals, TODOs, plans, open work>

## Suggested starting points
<If Dan is about to make changes, which areas to look at first — or what questions to answer before touching anything>
```

## Constraints

- Read only — do not suggest fixes, rewrites, or improvements yet
- Be specific: name files, patterns, and versions, not generalities
- Don't pad weak dimensions with faint praise
- If a dimension genuinely looks good, say so briefly and move on
- Surface ADR candidates if you notice decisions that appear undocumented but significant
- Keep the full report skimmable — detail in the table notes, not in prose walls
