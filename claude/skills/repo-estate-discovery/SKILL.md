---
name: repo-estate-discovery
description: Derive a team's real repository estate from a GitHub org when the documentation is stale, partial, or absent. Triangulates four independent angles — repo name patterns, commit authorship, ticket-key references, and issue-tracker records — and reconciles them into one evidence-scored map. Use when asked which repos a team actually owns, to confirm the services behind a rebuild or migration, to map repos to people, or when an estate catalogue names a gap that has to be filled from the code itself.
---

# Repo estate discovery

## Purpose

Answer "what does this team actually own?" from primary evidence, when the wiki
either does not say or cannot be trusted.

The output is not a repo list. It is an evidence-scored estate map plus the
organisational signal inside it: who works where, which repos have a bus factor
of one, which are stale behind an active-looking push date, and where the
declared team boundary and the commit graph disagree.

## Parameters

Collect before starting. Ask for what is missing; do not guess.

| Param | Example | Notes |
|---|---|---|
| `ORG` | `acme-corp` | GitHub org |
| `SUBJECT` | "NBA v2 rebuild" | What the estate is for |
| `NAME_HINTS` | `decisioning`, `ranking`, `action-store` | Candidate patterns; expect most to miss |
| `KNOWN_REPOS` | seed list | Anchors naming convention and calibrates search |
| `PEOPLE` | display names | Handles usually unknown at start — that is normal |
| `EMAIL_DOMAIN` | `acme.com` | For identity resolution |
| `TICKET_PREFIX` | `NBA` | Ticket keys in commit messages |
| `TRACKER` | Jira project key, Confluence space | Optional fourth angle |
| `WINDOW` | last 6 months | Recency cut-off |

`SUBJECT`, `NAME_HINTS` and `KNOWN_REPOS` are what make this project-agnostic.
Nothing below should mention a specific company, team, or ticket prefix.

## Governing principle

**Every search primitive here fails silently.** Each returns a well-formed,
plausible, wrong answer rather than an error. An empty result is never evidence
of absence until you have proved the query could have found something.

Corollary: run a **positive control** before trusting any negative. Query for
something you already know exists (`KNOWN_REPOS`). If the control returns
nothing, the harness is broken, not the estate.

## Phase 0 — auth preflight (mandatory)

Do this before any search. Skipping it invalidates everything after it.

**Precondition:** `gh` is already authenticated to at least one account. This
skill does not cover initial `gh auth login` setup — if `gh auth status` reports
no accounts, stop and set that up first.

```
gh auth status
gh api user/orgs --jq '.[].login'
```

Confirm the *active* account is a member of `ORG`. Multi-account setups are
common and the active account is often the personal one, which returns `[]` for
every org query — indistinguishable from "no such repos".

If another authenticated account has the membership, scope the token per
command rather than switching global state:

```
export GH_TOKEN=$(gh auth token --user <org-account>)
```

Positive control before proceeding:

```
gh search repos --owner "$ORG" "<a known repo>"
```

## The four angles

One angle is never sufficient. Each is blind to what the others catch, and the
blindness is not symmetric — discovery and confirmation come from different
angles. In the worked case the authorship angle surfaced an entire workstream
(three repos) that no name hint would have reached, because none of them matched
the expected convention; the ticket-key angle could not have found them first,
but it was what proved the workstream belonged to the subject at all, by showing
the subject's ticket keys landing in those repos.

### Angle 1 — name patterns

```
gh search repos --owner "$ORG" "<hint>" --limit 25 \
  --json fullName,description,language,updatedAt \
  --jq '.[] | [.fullName, (.language // "-"), .updatedAt[0:10], .description] | @tsv'
```

Run each `NAME_HINT` separately; do not concatenate. Derive the real convention
from what comes back, then re-run with it — the org's actual prefix is usually
not the one in the brief.

### Angle 2 — commit authorship

Resolves people to repos, and catches repos matching no name pattern. This is
the discovery angle: in the worked case it was the only one that surfaced a
whole adjacent workstream.

```
gh search commits --owner "$ORG" --author-name "<Full Name>" \
  --limit 100 --sort author-date --order desc \
  --json repository,author,commit
```

**Display-name search is unreliable and must be backstopped.** A person's git
author name is whatever their machine is configured with — often a bare handle,
sometimes a stale identity from an old laptop. Display-name search can return
only years-old commits while the person is committing daily under another
identity, which reads exactly like "they went inactive".

For every person, resolve to a GitHub login and re-run keyed on it:

```
gh api users/<login> --jq '[.login, .name, .company] | @tsv'
gh search commits --owner "$ORG" --author <login> --limit 100
```

Cross-check the login against a commit's author email in a repo you already
know they touched. A `firstname.lastname@$EMAIL_DOMAIN` match is confirmation;
a `noreply@github.com` address is not, and needs a second signal.

A person you cannot resolve is **unresolved**, not inactive. Report the
distinction explicitly — conflating them puts a live contributor in the
"departed" column.

### Angle 3 — ticket-key references

The attribution angle. It rarely discovers a repo the other angles cannot see;
what it does is prove *which* repos a workstream's tickets actually landed in,
and date the transitions. In the worked case it confirmed the subject's ticket
keys in repos that Angle 2 had surfaced, and pinned the exact date a
contributor's commits switched from the core services to the adjacent
workstream — a reallocation finding neither other angle could produce.

It is also the angle most likely to be skipped, because its value is
confirmation rather than novelty.

```
gh search commits --owner "$ORG" "$TICKET_PREFIX-NNNN" --limit 50
gh search prs --owner "$ORG" "$TICKET_PREFIX-NNNN" --limit 50
```

**Post-filter every hit for a literal case-insensitive substring match on the
key.** GitHub tokenises the query, so `ABC-3000` also matches any text
containing `ABC` and any PR numbered `#3000`. One run is not a rate, but in the
worked case 11 ticket keys were queried and only 4 survived the literal filter
with genuine repo matches (5 repo-and-key pairs, one key hitting two repos).
Everything else was tokenisation noise — and entirely credible-looking noise if
you do not filter.

### Angle 4 — issue tracker and wiki

**UNVERIFIED — barely exercised in the session this skill was derived from.
Treat the calls as a starting point and confirm behaviour before relying on
results.**

Where an Atlassian MCP is connected, query the tracker directly for the same
tickets and for repo references:

- `searchJiraIssuesUsingJql` — `project = <KEY> AND updated >= -26w`, to get the
  live ticket set rather than a hand-supplied sample, and to see which keys have
  no code against them at all
- `getJiraIssueRemoteIssueLinks` — explicit ticket-to-PR links, which would
  bypass the tokenisation problem in Angle 3 entirely if the team uses the
  integration. **Tried on three issues in the worked case and returned empty for
  all three** — the Jira/GitHub dev-panel data was not exposed this way. One
  data point, not a verdict: check it early rather than budgeting for it
- `searchConfluenceUsingCql` — the existing estate page, read as a *claim to be
  tested*, never as a source

The value here is the inverse direction: tickets with no commits. That gap
distinguishes "not started" from "on an unmerged branch" — which Angle 3 alone
cannot do.

## Merging the angles

The angles produce overlapping, partly contradictory evidence. Merge
deliberately.

**1. Build the identity spine first.** One person maps to N git identities:
`person → github login → {author names} → {emails}`. Resolve this before any
join. Every subsequent join keys on **login**, never on display name. Repos key
on `owner/name`, never the short name.

**2. Treat each angle as evidence rows, not conclusions.** One row per
(repo, signal, source, date). Merge by union, then score — do not have a later
angle overwrite an earlier one.

**3. Score confidence.**

- **Confirmed** — two or more independent angles agree, or one angle plus a
  verified tech signature read from file contents
- **Probable** — a single angle, unverified
- **Rejected** — matched a search but failed the literal post-filter

Verify tech signatures against real files rather than accepting a description.
Search the repo's code and dependency manifests for the claimed stack. In the
worked case a service described as using a managed ML platform declared no such
dependency anywhere — the actual ML code was in a separate repo with a separate
owner. That correction was the single most valuable output of the exercise, and
only surfaced because the manifest was read rather than the description.

**4. Compute recency honestly.** Three different dates get conflated:

- `pushed_at` — any push to any branch, including bots
- last commit on the **default branch** — what most tooling reports
- last commit by a **human** — strip `[bot]`, `dependabot`, `*-bot` first

Report the human default-branch date as "last commit". Where `pushed_at` leads
it by months, the work is on non-default branches — surface that as a finding,
not a footnote. Check the default branch name too; it is not always `main`, and
a repo whose default is a deployment branch can look abandoned while being
actively developed.

**5. Note truncation.** Search caps at 100 results. Record the oldest date
returned per query; if it is inside `WINDOW`, the result is a floor, not a
complete list, and must be labelled as such.

## Rate limits

The search API secondary-limits and returns HTTP 403 well before any documented
hourly quota is exhausted. A naive loop swallows this as zero rows per person —
the failure that most convincingly imitates a real answer.

Detect `HTTP 403` explicitly, back off, retry, and log per-query outcomes to a
file so successes and rate-limited zeros stay distinguishable. Pace sustained
scans with a deliberate gap between calls and run them in the background rather
than blocking.

**Thresholds observed once, not verified:** roughly ten rapid calls before a
403, 75–90s of backoff clearing it, ~12s spacing sustaining a scan. Treat these
as a starting configuration and adjust from the log, not as published limits —
they come from a single session and GitHub does not document them.

## Failure modes (reference)

| Symptom | Reads as | Actual cause |
|---|---|---|
| Every org query returns `[]` | Repos do not exist | Active account not an org member |
| A batch of people return 0 commits | They do not commit here | Secondary rate limit swallowed as empty |
| Person's commits stop years ago | They went inactive | Current commits under a different author identity |
| A ticket key hits many repos and years | Broad blast radius | Search tokenised; matched substrings and PR numbers |
| Ticket keys return nothing | Work not started | Commit search indexes default branches only |
| Repo looks active | Healthy | `pushed_at` driven by bots or non-default branches |

## Reporting

Per repo: URL, description, primary language, created date, last **human**
commit on the default branch, contributors with commit counts, confidence tier,
and which angles found it.

State caveats inline, not in a trailing disclaimer: which queries truncated,
which people are unresolved, which findings rest on a single angle.

Then read the map for organisational signal, which is usually the actual
deliverable:

- **Disjoint workstreams** — clusters of people who never commit to the same
  repos, under one team name
- **Bus factor of one** — single-contributor repos, especially infrastructure
- **Stale default branches** — long-lived divergence between `pushed_at` and
  the default branch
- **Reallocation** — a key contributor's recent commits having moved to repos
  outside the nominal remit
- **Boundary mismatch** — repos carrying the team's ticket prefix that nobody
  has catalogued as theirs

Separate observation from inference throughout. "Contributor X has not
committed to service Y since March" is an observation. "X moved teams" is a
hypothesis — name it as one, and name what would confirm it.
