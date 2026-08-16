# Engineering Defaults

Read the section whose event has fired, not the whole file. "Working on an engineering task" was the previous trigger and it is a mode, not an event — true of nearly every session, so it fired on judgement rather than on a moment, which means it mostly did not fire at all.

| Event                                                          | Section                                                    |
| -------------------------------------------------------------- | ---------------------------------------------------------- |
| Starting work that will generate its own requirements or decisions | Feature Boundaries                                         |
| Before committing, branching, merging, or opening a PR         | Git Discipline · Engineering Defaults                      |
| Before claiming a fix, test, probe, or check succeeded         | Verification Before Claiming Success                       |
| Before dispatching a background subagent                       | Watching Long Background Work                              |
| Writing or structuring new code                                | Code Quality · Coding Preferences · Architecture Default   |
| Choosing which quality gates a piece of work warrants          | The Verification Stack                                     |
| Configuring a project's nWave rigor or DES setup               | nWave Rigor Profile                                        |

**Use nWave directly, not just its philosophy.** These defaults describe nWave's approach — don't approximate them ad hoc. Reach for the actual skill suite: `/nw-new` to route new work to the right wave, `/nw-buddy` for any methodology question, `/nw-continue` to resume. Wave commands (`/nw-discuss` → `/nw-design` → `/nw-distill` → `/nw-deliver`, `/nw-review`, `/nw-mutation-test`) and the custom `nw-*` agents and hooks are how the consistency and discipline get enforced — prefer them over hand-rolled equivalents.

## Feature Boundaries

`/nw-new` for anything that will generate its own requirements or decisions. Extend an existing
`feature-delta.md` only to refine requirements already in it.

You have outgrown a boundary when the delta passes ~300 lines, requirement IDs run past ~E12, or you
cannot answer "what would finalize this feature?" — split before continuing, not after.

**Skipping the wizard means owning its work.** Reaching for `/red`, `/green` or `/nw-deliver`
directly is fine for mechanical increments, but say which feature ID you are working in and which
wave you are entering. `/nw-new` also decides the feature ID, checks for name conflicts, and routes
bugs to `/nw-root-why` and unvalidated problems to `/nw-discover` — skip it and every increment
silently enters at DELIVER.

Wave completion is detected from artifacts, not from memory: `tests/acceptance/{id}/`,
`deliver/execution-log.json`, `docs/product/kpi-contracts.yaml`. If a wave genuinely happened but its
artifact does not exist, say so — and do not create the artifact just to satisfy the check, which is
manufacturing evidence.

## Engineering Defaults

- Conventional commits; trunk-based development
- Branch lifecycle: feature branch → `/check` → push → MR → merge → `git checkout main && git pull` → `git branch -d <branch>`. Always branch from a pulled main. Never carry uncommitted work across stories.
- Pre-commit: where lefthook is configured, it runs `pnpm test --run` and blocks commits with failing tests. Not universal — check for a lefthook config before assuming a repo has any pre-commit gate at all
- Pre-push: where trunk is configured, enable its `trunk-check-pre-push` action so formatting and lint drift cannot reach the remote. Prefer this over `trunk-fmt-pre-commit` on any machine where a sandboxed session commits: trunk cannot run under the Claude sandbox, so a pre-commit hook invoking it aborts every such commit
- CI gates: dep-cruiser dependency enforcement (failing build); SAST, SBOM when applicable
- IaC; Docs as Code; Diagrams as Code (Mermaid default, PlantUML + C4Model for architecture)
- Decision Records for significant architectural choices — captured through nWave wave artifacts
- Epics and stories: who + what + why + AC; tackle technical risk early

## Git Discipline

- **Never commit to `main`.** Branch first, always from a pulled main.
- **Never `git add -A` or `git add .`.** Stage named paths only, so unrelated files (`.trunk/`, lint config, `.idea/`, generated output) are never swept in.
- **Verify the push landed before deleting a branch** — `git log origin/<branch> -1`.
- **Never rewrite or reset `main`'s ref.** If history surgery looks necessary, stop and ask.
- **Never squash-merge.** Merge with a merge commit, or rebase-merge. Both preserve the individual
  commits; squash discards them.

  Why it matters here specifically: commits are required to be atomic and to explain the *why* in
  the body, and `git log` is the changelog. Squashing collapses that reasoning into one message and
  throws the rest away — it destroys the artifact the discipline exists to produce. It also
  **orphans stacked PRs**: squashing rewrites the base branch's commits, so every layer above no
  longer shares history with it and conflicts on the next rebase.

  Choose by intent: **rebase-merge** for a linear history when the branch is tidy; **merge commit**
  when the branch boundary is worth keeping visible. Never squash to tidy a messy branch — rebase
  interactively on the branch first, so the tidying is a deliberate act with a reviewable result.

  Enforce it mechanically rather than by memory: on repos you own, set
  `allow_squash_merge=false` so `gh pr merge --squash` fails at the API instead of relying on
  nobody reaching for it.

- **Set `delete_branch_on_merge=true` on repos you own.** GitHub retargets a dependent PR to the
  trunk only when its base branch is deleted on merge. With deletion off, every layer of a stack
  needs a manual `gh pr edit --base` — and a missed retarget merges a stacked PR into a branch
  instead of the trunk, which looks like success and lands nothing.

**Stacked PRs** are the PR-level form of the feature-boundary rule above: prefer several small
reviewable layers over one large diff. `gh stack` (GitHub's own CLI extension) manages the chain.
Merge bottom-up, never squash, and `gh stack sync` after any mid-stack change. The tooling does not
create the decomposition — name the layers before writing, and if they cannot be named, the work is
not decomposed yet.

## Verification Before Claiming Success

- Never state that a fix, probe, or test works based on inference. Paste the actual command output, test count, or screenshot.
- **Never silence a diagnostic.** No `2>/dev/null` on a command whose result you are about to reason about — a swallowed error reads as an absence. Treat a non-zero exit as a real failure.
- **An empty result is not a pass.** A check that examined nothing prints exactly what a clean check prints, so make it state its scope — file count, test count, exit code — and read that before believing it. Two silent-zero traps: a glob that matched nothing, which under zsh's `nomatch` may abort the command before it runs at all; and a linter invoked without the repo's `--config`, which then reports against the wrong ruleset in both directions. Unquoted variables do not word-split in zsh either, so `$FILES` holding two paths arrives as one nonexistent filename and lints zero files, silently. A fourth lives under Harness Constraints in `~/.claude/CLAUDE.md`: process substitution is sandbox-denied, so `diff <(…) …| wc -l` prints `0` — which reads as *files identical*.
- **Name the tool and its version, or the check proves nothing.** A linter you invoked is not necessarily the linter that will judge you. Run the command the CI script names, verbatim, rather than an equivalent assembled by hand — `trunk check --all --no-progress` rather than a `prettier` binary located under `~/.cache/trunk`, where two versions sat side by side and the one picked by guessing passed files that CI then rejected.
- When adding a constant, config value, or helper, grep for its consumer. Unit-tested but never read by production code is not wired.
- For visual or layout behaviour, ask for a live screenshot rather than inferring how it renders.

## Watching Long Background Work

A background subagent can run 15–30 minutes silently, and there is no live introspection into it:
`TaskOutput` is deprecated for agent tasks and the `.output` file is the full JSONL transcript. So
before dispatching one, arm a `Monitor` on a cheap **external** probe — test count, commit count, an
artifact's size — and print only when the derived state changes. `/watch` carries the recipes.

- **A terminal condition that could already be true before the work starts is vacuous.** In model
  checking this is *antecedent failure*, and the finding there is that trivial validity always
  indicates a real defect rather than a lucky pass. Require evidence of the *transition* — RED was
  observed, the total grew, N commits landed — never the end state alone.
- **Structure arrives before substance.** Probe counts, not existence: an agent writes its headings
  in the first minute, so "the Sources section exists" is true of an empty document.
- **Three verdicts.** A watch that ends without observing the transition is *inconclusive*, not
  successful. Never round it up to done, and never report a monitor's terminal event as proof the
  work succeeded — read the agent's actual result too.

- **Probe the artifact, not the agent's account of it.** The task list (`TaskCreate`/`TaskUpdate`/
  `TaskList`) is the right tool for tracking progress against a plan, including across subagents —
  but it is self-reported, and it is poll-only. Tests, commits and build output were produced by the
  work rather than described by it. Use the task list for what the agent believes; probe for what
  changed; treat disagreement between them as a finding.

`claude/hooks/monitor-guard.sh` prompts these questions whenever a `Monitor` that can terminate is
armed, because the judgement is needed at the moment the condition is written.

The retired `/plan` skill hand-rolled `.claude/task_plan.md`, `findings.md` and `progress.md` before
plan mode and the `Task*` tools existed. Use the built-ins — they carry ownership and dependencies
that markdown files never did.

## Code Quality

- Minimal implementation — don't over-engineer
- No speculative abstractions, future-proofing, or unsolicited refactors
- Comments: see **Code Comments** in `~/.claude/CLAUDE.md` — that is the single home for comment policy, including the no-annotations-on-unchanged-code rule that used to live here
- Validate at system boundaries only; trust internal code and framework guarantees
- No backwards-compatibility shims for code that has no consumers
- **Testing Theater:** A passing test suite with no genuine behavioural assertions is worse than no tests — it creates false confidence. Before committing a test, apply the deletion check: delete the production code this test covers; does the test fail? If not, it's Theater. Theater patterns: zero-assertion tests, tautological assertions (`assert result is not None`), mocks that return the expected value directly, circular verification (expected recomputed from same formula as production).

## nWave Rigor Profile

Default rigor: most gates are on-demand, not mandatory — run them when you have tokens to spare or before a change you're uncertain about. This default assumes a personal/Pro-tier project; check the project's own context (CI config, `.nwave/des-config.json`) before assuming it applies on a work repo. **Exception: reviewer / peer-review agents always run** (see below).

- **Reviewers always run** — the paired `nw-*-reviewer` peer-review gates and `/nw-review` are mandatory, not on-demand. Rationale: they catch tangents and unfounded directions early, which saves net tokens versus discovering the detour later. Never skip a wave's reviewer gate to "stay lean" — running it *is* the lean choice.
- Mutation testing: Stryker, target 85% kill rate on core modules — run via `/nw-mutation-test`, not as a merge gate (scope defined per project)
- All other nWave wave commands follow the same principle: invoke explicitly, don't treat as mandatory pipeline steps
- The DES pre-bash hook blocks ANY Bash command whose text contains `execution-log` — including `git rm` at finalize. Read it via the `Read` tool; discard it via directory-level `git rm -r deliver/`.
- `execution-log.json` is intentionally empty for SKILL.md-only features (no compiled TDD phases to instrument)
- `.nwave/des-config.json` MUST declare `"rigor": {"tdd_phases": ["RED", "GREEN", "COMMIT"]}` in every project using the 3-phase ADR-025 canon. Since nwave-ai v3.15, an absent `rigor.tdd_phases` defaults to the LEGACY 5-phase list (PREPARE/RED_ACCEPTANCE/RED_UNIT/GREEN/COMMIT) and `des-verify-integrity` then FAILS 3-phase execution logs (empirically confirmed 2026-06-10). Other rigor keys absent → lean on-demand defaults still apply. The file is gitignored — set it per machine/clone.

## Coding Preferences

- FP-leaning by default: pure functions, explicit data flow, pipeline composition over mutation
- Prefer `Result<T,E>` over thrown exceptions for recoverable failures
- `map`/`filter`/`reduce` over imperative loops
- Lifecycle-prefixed types: `UnvalidatedOrder` → `ValidatedOrder` — stage visible in signatures
- Feature-oriented organisation: by domain, not technical layer
- Point-free and monad abstractions: aspirational — favour readability over cleverness until fluency arrives

## Architecture Default

**Pure Core / Imperative Shell** (hexagonal via functions, not classes) is the default for any project with a domain model, persistence, or external services:

- Business logic in pure functions; all I/O and side effects at adapters
- Ports are function type signatures; adapters are functions matching those signatures
- Dependency injection via parameter passing — no DI containers
- Enforce the boundary with **dependency-cruiser** in CI; without enforcement the boundary is convention, not architecture
- Override explicitly for scripts and one-off tools where the structure adds no value

## The Verification Stack

Layered quality practices — each catches what the layer below misses. Apply bottom-up. These are gates invoked deliberately and by name, not a checklist to run before every response. The adversarial review layer sits above all others — an independent posture that assumes nothing and verifies everything: Radical Candor (kind *and* clear), blocking issues named specifically, Testing Theater detected, test modification caught, YAGNI violations flagged, AC coverage verified.

- **dependency-cruiser** — enforces Pure Core / Shell boundary mechanically in CI; makes architecture load-bearing
- **Pure Core / Shell** — purity means no hidden state, no mocking needed, nowhere for bugs to hide
- **Mutation testing** — verifies tests catch real bugs, not just execute lines; target 80-85% kill rate on core modules
- **Property-based testing** (fast-check) — verifies tests cover the right input space; reach for it on: serialisation/roundtrips, state machine transitions, algorithms, any domain with algebraic rules (associativity, idempotency, commutativity)
- **Outside-In TDD** — double loop: BDD acceptance test (outer) drives inward to unit tests (inner); acceptance test prevents TBU (Tested But Unwired)
- **Walking Skeleton** — entry point for any new feature; proves all architectural layers connect before building out. A skeleton proves _architecture risk_ is resolved; an MVP proves _value risk_. Don't conflate — skeleton should be obviously incomplete
- **Algebra-Driven Design** — for combinable/transformable domains: define rules (equations) before implementation; rules become PBT properties automatically
- **TLA+** — ceiling for distributed/concurrent systems where empirical testing can't reach all interleavings; use for consensus, coordination, distributed transactions
