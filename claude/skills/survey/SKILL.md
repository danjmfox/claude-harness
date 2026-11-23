---
name: survey
description: Assess a codebase before making any changes, so the reader can orient and start work. Covers purpose, coherence, complexity, currency, idiomatic use, tooling, module structure, and consistency between code and docs. Surfaces existing plans, decision-record state, work in flight, who decides what, and a first-hour reading path. Use at the start of a chat to orient before touching anything.
---

Conduct a structured assessment of the current repository. $ARGUMENTS

Type: How-To. Goal: produce an honest orientation report that a newcomer can act on.

This is a read-only pass. Do not suggest changes. Run the repo's own gates only when `$ARGUMENTS` contains the word `verify` (see Verify mode).

## Evidence rules

- Every count states how it was obtained (command, pattern, or "read by hand"), so the reader can distrust it.
- Every date names its source: `git` (last commit touching the file), `header` (date written in the file), or `code` (last commit touching related code). Prefer `git`. When sources disagree, report both.
- Never report a bare `grep` hit count as a finding. Read each match and classify it.

## Step 1 — Gather signals

Read broadly before forming opinions. In parallel where possible:

- Ref: run `git fetch -q`, then `git rev-list --count HEAD..origin/<default>`. When the count is above 0, read through `git show origin/<default>:<path>` and `git grep ... origin/<default>` instead of the working tree, and name the surveyed ref in the report title. If the fetch fails, list it under "What I could not check".
- Root files: `README.md`, `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml`, `CHANGELOG.md`, `.mise.toml`, `Makefile`, `docker-compose.yml`
- CI/CD: `.github/workflows/`, `.gitlab-ci.yml`, `.travis.yml`
- Config: `.eslintrc*`, `tsconfig.json`, `trunk.yaml`, `vitest.config.*`, `prettier.config.*`
- Docs: `docs/`, `ADR/`, `decision-records/`, any `*.md` beyond the root
- Plans: `.claude/task_plan.md`, `ROADMAP.md`, `TODO.md`, open issue references in code comments
- Governance: `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, `CODEOWNERS`, PR template
- Source structure: top-level directories, module boundaries, test layout
- Recent history: `git log --oneline -20`
- Remote branches: `git for-each-ref --sort=-committerdate --format='%(committerdate:short) %(refname:short)' refs/remotes`
- Dependencies: outdated runtimes, deprecated packages, known-insecure versions

## Step 2 — Assess each dimension

Evaluate each lens. Be honest and specific, noting strengths and weaknesses.

### Purpose
Does the README state who the project is for, what it does, and how to get started? Does the code match?

### Overall coherence
Is the codebase unified or a patchwork? Check naming, folder structure, and architecture for consistency.

### Complexity
Is the complexity appropriate for the problem? Look for unnecessary abstraction layers, deeply nested logic, large files, circular dependencies, god modules, config sprawl.

### Currency
- Runtime and major dependency versions against current LTS/stable.
- Last meaningful commit: actively maintained or quietly stale?
- CI/CD approach: modern, legacy, or absent?
- **Freshness check.** For each orientation doc (README, architecture notes, setup guides, CLAUDE.md), run `git log -1 --format=%cs -- <file>` and compare with the date in its header and with `git log -1 --format=%cs -- <related code dir>`. Call a doc stale only when the git date trails the related code. A stale header over a current body is a header problem, not a doc problem. Bulk commits (formatters, renames) make git dates optimistic; note it when several files share one date.

### Relevance
Look for dead areas: unused dependencies, commented-out code, unreferenced files, stale branches, features in docs but absent from code.
- **Skipped-test inventory.** Search for the framework's skip markers, not the bare word `skip`. Use fixed strings (`git grep -nF -e '.skip(' -e '.todo(' -e skipIf -e runIf`; add `@pytest.mark.skip` or `t.Skip(` for other stacks) and keep the leading `.` so `earlyExit(` does not match `it(`. On macOS, `git grep -E` returns nothing for `\b` and `\w` with no error, so use `-F`, `-w` or `[[:space:]]` instead. A zero or a handful in a repo with an obvious skip convention is a signal to re-run with another pattern.
  Read each match and classify it as *abandoned* (no condition, no ticket, old) or *conditional* (env variable, missing fixture, platform guard). Classify a conditional skip from the guard it sits behind, match by match where practical and by file at least. Report both counts, the rule used, and which of the two granularities was used.

### Idiomatic use
Does the code use the language and framework as intended? Flag reinvented built-ins, fighting the framework, outdated patterns for the current version.

### Contemporary approach
Does the overall approach reflect current thinking in architecture, state management, API design, auth, observability, and error handling?

### Tools
Assess package manager, task runner, linter, formatter, test framework, CI provider. Note gaps (no linter, no tests, no CI). Check that CI path filters and globs cover every source tree.

### Module structure
Are module boundaries clear? Is there coupling that should be decoupled, or splits that add friction?

### Consistency — code and documentation
Does the code match the docs? Confirm README setup steps (runtime version, install, hook commands) match what CI requires. Check whether conventions hold across eras and contributors, and whether test style is uniform.

### Future plans
Surface signals of intended direction:
- `.claude/` plan files, `ROADMAP.md`, `TODO.md`, the `CHANGELOG.md` Unreleased section
- TODO/FIXME/HACK comments (sample; do not list exhaustively)
- **Decision-record census.** Count records by status (frontmatter or header `Status`). List each Proposed record with its last git edit date and age in days; flag any older than 30 days. Report the count method.
- **Work in flight.** Group open remote branches by topic prefix, with last commit date. For each branch from the last 30 days, run `git diff --stat origin/<default>...<branch>` and note the files it touches.

### Who decides what
Quote the human/agent division, approval gates, and ownership rules from the governance files in Step 1. List open decisions (Proposed records, unresolved RFCs). Write "none found" when the repo states none.

## Step 3 — Summarise

Lead with a one-paragraph overall impression, then the table. Rate each dimension **Strong** / **Adequate** / **Weak** / **Absent**.

```
## Survey: <repo name> @ <ref surveyed>

<One paragraph: purpose, condition, main concerns>

## First hour
1. Read, in order: <3-5 files, one line each on why>
2. Prove setup works: `<one command>`
3. Daily commands: `<test>`, `<lint>`, `<build>`, `<run>`

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
- <what is working well>

## Key concerns
- <specific, not generic>

## Future plans detected
- <roadmap signals, TODOs, decision-record census, work in flight>

## Who decides what
- <division, gates, open decisions>

## Suggested starting points
<Areas to look at first, or questions to answer before touching anything>

## What I could not check
- <audit, depcheck, gates, anything skipped, and why>
```

"What I could not check" is mandatory. Write "nothing skipped" only after confirming it.

## Verify mode

Off by default. Enable only when `$ARGUMENTS` contains `verify` (for example, `/survey verify`). Run the repo's own gates once (the commands from First hour, plus the dependency audit if one exists), report pass or fail with the exit status, and change nothing else. Without the word `verify`, list the gates under "What I could not check".

## Constraints

- Read only by default. Do not suggest fixes, rewrites, or improvements.
- Name files, patterns, and versions, not generalities.
- Do not pad weak dimensions with faint praise. If a dimension looks good, say so briefly and move on.
- Surface decision-record candidates for decisions that look significant but undocumented.
- Keep the report skimmable: detail in the table notes, not in prose.

## Backlog

Single data point (one browser-extension repo, 2026-08-13). Promote only when a second repo shows the need.
- Secrets scan of workflows and scripts for embedded credentials or tokens
- Contributor files: `LICENSE`, `CONTRIBUTING`, `CODE_OF_CONDUCT` presence and currency
- Release semantics: package version vs tag vs changelog
- Domain-specific checks (locale, accessibility, build-size budgets, mutation testing)
