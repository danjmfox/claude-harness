---
name: ship
description: Branch, open a draft PR immediately, stage only the files you changed, prove tests green, push, and mark the PR ready for review. Never commits to main, never uses git add -A. Use at the start of a piece of work — the draft PR opens first, not at the end — and again to mark it ready.
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

2. **Open a draft PR immediately**, against the base from step 1 — before there's a finished diff
   to show. This makes the base a visible, tracked fact from the start rather than a spoken one,
   gives `gh stack` something to track from commit one when this branch is a stack layer, and lets
   CI start running early instead of only once the branch looks "finished."
   - Forges refuse a PR/MR with zero commits ahead of the base. Push whatever already exists —
     `nw-new`'s scaffold commit, or `git commit --allow-empty -m 'wip: <slug>'` if truly nothing
     does yet — then push the branch.
   - `github.*` → `gh pr create --draft --base <base> --title '<type>: <slug>' --body 'WIP'`
   - `gitlab.*` → `glab mr create --draft --target-branch <base> --title '<type>: <slug>'`
   - One PR per branch. Step 10 converts this one to ready — it does not open a second.

3. **Enumerate what changed.** Run `git status --porcelain`. List every path and classify it:
   - **Mine** — files this piece of work actually touched.
   - **Not mine** — pre-existing modifications, tool noise (`.trunk/`, lint config, `.idea/`,
     generated output), or unrelated work.

   State the split explicitly. If a file contains both your change and someone else's
   uncommitted work, say so — it cannot be separated without hunk-level staging.

   **If the work is already committed on this branch**, steps 4–5 have nothing to stage. Skip them
   and review `git diff <base>..HEAD` instead — the point of step 5 is a last look at exactly what
   will land, and that is just as reachable after committing as before.

4. **Stage by name.** `git add <path> <path> …` for the "mine" set only.
   **Never `git add -A` and never `git add .`.** Leave everything else unstaged.

5. **Show the staged diff and stop.** Run `git diff --cached --stat` plus the full diff, and wait
   for confirmation before committing. This is the last cheap moment to catch a stray file.

6. **Prove the tests pass.** Run the project's test command (check `.mise.toml`, `package.json`,
   `Makefile`) and **paste the actual output including the pass count**. Do not proceed on red,
   and do not describe the result without showing it. If the suite cannot run in the current
   environment, say so plainly and hand over the command rather than claiming a pass.

7. **Commit.** Conventional commit; subject says what, body says *why*. Atomic — one logical
   change per commit.

8. **Push.** `git push origin <branch>`. Avoid `-u`: setting upstream writes to `.git/config`,
   which is denied in some sandboxes, and the failure is reported as if the push itself failed.
   Set tracking separately afterwards if it is wanted.

9. **Verify the push landed** before anything destructive: `git log origin/<branch> -1`. Only
   after this may a branch be deleted, ever.

   **Step 8's exit code is not the answer — this step is.** A push can succeed while the command
   still exits non-zero (upstream config denied, hook noise, a warning on stderr). Read the remote
   ref, not the exit status.

10. **Mark the draft PR ready for review** — the one opened in step 2, never a second one. Update
    its title/description with what changed, why, and how it was verified, then un-draft it:
    - `github.*` → `gh pr edit <n> --title '...' --body '...'` then `gh pr ready <n>`
    - `gitlab.*` → `glab mr update <n> --title '...' --description '...' --ready`

    **Never squash-merge**, and never suggest it. Use a merge commit or a rebase-merge — both keep
    the individual commits. `gh pr merge --squash` / `glab mr merge --squash` are prohibited: they
    discard the per-commit reasoning and orphan any PR stacked on this branch.

    `gh pr merge` and `glab mr merge` can print **nothing at all** on success. Never read silence
    as failure or as success — check the PR state (`gh pr view <n> --json state,mergeCommit`).

## Prohibitions

- Never commit to `main`/`master`.
- Never `git add -A` or `git add .`.
- Never delete a branch before step 9 confirms the push.
- Never rewrite or reset the default branch's ref. If history surgery looks necessary, stop and ask.
- Never bypass hooks with `--no-verify` — if a hook blocks, that's a finding, not an obstacle.

## Stacked PRs

Prefer several small reviewable layers to one large diff. `gh stack` (GitHub's own CLI extension)
manages the chain; each branch's PR is based on the branch below it, so a reviewer sees only that
layer's diff. Step 2 already opens each layer's draft PR against the layer below as soon as that
branch exists — stacking needs nothing extra at creation time, only the discipline below at merge
time.

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
- The draft PR URL from step 2, and its base
- The staged set, and the deliberately-unstaged set with a reason for each
- The verbatim test output
- The commit SHA, the push confirmation from step 9, and confirmation the PR was marked ready
