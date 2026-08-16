---
name: ship
description: Branch, stage only the files you changed, prove tests green, push and open an MR/PR. Never commits to main, never uses git add -A. Use when a piece of work is finished and ready to go out.
disable-model-invocation: true
---

Ship the current work. Follow every step in order — the ordering is the point.

**Optional scope note:** $ARGUMENTS

## Instructions

1. **Check the branch.** Run `git rev-parse --abbrev-ref HEAD`.
   - If on `main` (or `master`), create a branch first: `git switch -c <type>/<slug>` using a
     conventional-commit type. Do not commit to the default branch under any circumstances.
   - If already on a feature branch, confirm it's the right one before continuing.
   - **Determine the base and state it.** Usually the trunk. But if this work builds on another
     branch that has not merged yet, the base is *that branch* — not the trunk. Getting this wrong
     puts an unrelated diff in the review. See Stacked PRs below.

2. **Enumerate what changed.** Run `git status --porcelain`. List every path and classify it:
   - **Mine** — files this piece of work actually touched.
   - **Not mine** — pre-existing modifications, tool noise (`.trunk/`, lint config, `.idea/`,
     generated output), or unrelated work.

   State the split explicitly. If a file contains both your change and someone else's
   uncommitted work, say so — it cannot be separated without hunk-level staging.

   **If the work is already committed on this branch**, steps 3–4 have nothing to stage. Skip them
   and review `git diff <base>..HEAD` instead — the point of step 4 is a last look at exactly what
   will land, and that is just as reachable after committing as before.

3. **Stage by name.** `git add <path> <path> …` for the "mine" set only.
   **Never `git add -A` and never `git add .`.** Leave everything else unstaged.

4. **Show the staged diff and stop.** Run `git diff --cached --stat` plus the full diff, and wait
   for confirmation before committing. This is the last cheap moment to catch a stray file.

5. **Prove the tests pass.** Run the project's test command (check `.mise.toml`, `package.json`,
   `Makefile`) and **paste the actual output including the pass count**. Do not proceed on red,
   and do not describe the result without showing it. If the suite cannot run in the current
   environment, say so plainly and hand over the command rather than claiming a pass.

6. **Commit.** Conventional commit; subject says what, body says *why*. Atomic — one logical
   change per commit.

7. **Push.** `git push origin <branch>`. Avoid `-u`: setting upstream writes to `.git/config`,
   which is denied in some sandboxes, and the failure is reported as if the push itself failed.
   Set tracking separately afterwards if it is wanted.

8. **Verify the push landed** before anything destructive: `git log origin/<branch> -1`. Only
   after this may a branch be deleted, ever.

   **Step 7's exit code is not the answer — this step is.** A push can succeed while the command
   still exits non-zero (upstream config denied, hook noise, a warning on stderr). Read the remote
   ref, not the exit status.

9. **Open the review** against the base from step 1 — pass it explicitly, never rely on the
   default. Detect the forge from `git remote -v`:
   - `gitlab.*` → `glab mr create --target-branch <base> --fill`
   - `github.*` → `gh pr create --base <base>`

   Include what changed, why, and how it was verified.

   **Never squash-merge**, and never suggest it. Use a merge commit or a rebase-merge — both keep
   the individual commits. `gh pr merge --squash` / `glab mr merge --squash` are prohibited: they
   discard the per-commit reasoning and orphan any PR stacked on this branch.

   `gh pr merge` and `glab mr merge` can print **nothing at all** on success. Never read silence as
   failure or as success — check the PR state (`gh pr view <n> --json state,mergeCommit`).

## Prohibitions

- Never commit to `main`/`master`.
- Never `git add -A` or `git add .`.
- Never delete a branch before step 8 confirms the push.
- Never rewrite or reset the default branch's ref. If history surgery looks necessary, stop and ask.
- Never bypass hooks with `--no-verify` — if a hook blocks, that's a finding, not an obstacle.

## Stacked PRs

Prefer several small reviewable layers to one large diff. `gh stack` (GitHub's own CLI extension)
manages the chain; each branch's PR is based on the branch below it, so a reviewer sees only that
layer's diff.

- **Merge bottom-up, always.** The layer closest to the trunk goes first.
- **Never squash** — it rewrites the base branch's commits, so every layer above stops sharing
  history with it and conflicts on the next rebase.
- **`gh stack sync` after any mid-stack change**, so the layers above pick it up.
- **`delete_branch_on_merge=true` on the repo.** GitHub only retargets a dependent PR to the trunk
  when its base branch is deleted on merge. Without it, retarget by hand (`gh pr edit <n> --base
  <trunk>`) *before* merging — a stacked PR merged into its still-existing base succeeds and lands
  nothing on the trunk, which reads as success.
- The tooling does not create the decomposition. Name the layers before writing; if they cannot be
  named, the work is not decomposed yet.

## Output

- The branch name used, and whether it was created or already existed
- The staged set, and the deliberately-unstaged set with a reason for each
- The verbatim test output
- The commit SHA, the push confirmation from step 8, and the MR/PR URL
