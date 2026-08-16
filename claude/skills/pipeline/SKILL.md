---
name: pipeline
description: Fetch and fix GitLab CI pipeline failures for the current branch using glab. Use after a push when CI fails to avoid manual copy-paste from the GitLab UI. Requires glab CLI authenticated.
compatibility: Requires glab CLI authenticated to gitlab.com (`glab auth login`)
---

Fetch and fix failures from the latest GitLab CI pipeline for the current branch.

## Instructions

### 1. Get pipeline status

```bash
glab ci view --branch $(git branch --show-current)
```

Identify all failed jobs. If no failures, report success and stop.

### 2. Fetch logs for each failed job

For each failed job, get its trace:

```bash
glab ci trace <job-name> --branch $(git branch --show-current)
```

Capture the tail of each log (errors are usually at the bottom).

### 3. Analyse and group failures

Group errors by type:

| Type          | Signals                                             |
| ------------- | --------------------------------------------------- |
| **Lint**      | ESLint errors, Prettier diffs, Trunk violations     |
| **Typecheck** | TypeScript errors (TS2xxx codes)                    |
| **Test**      | Vitest failures, assertion errors, missing coverage |
| **Security**  | SAST findings, dependency audit, secret detection   |
| **Build**     | Compilation errors, missing modules                 |
| **Container** | Docker build failures                               |
| **SBOM**      | CycloneDX generation errors                         |

### 4. Present findings

For each failed job:

- Job name and stage
- Root cause (one sentence)
- Relevant error lines (not the full log — just what matters)
- Proposed fix

### 5. Fix

- Fix issues one job at a time, starting with the earliest stage
- After fixing, confirm with: "Run `/check` to verify locally before pushing"
- If an error reveals an architectural issue worth capturing: suggest `/adr`

## Constraints

- Do not push automatically
- Do not fix security findings without explaining the vulnerability first
- If a SAST or dependency finding is a false positive, say so explicitly and suggest suppression with justification
