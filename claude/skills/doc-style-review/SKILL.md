---
name: doc-style-review
description: Review documents against this harness's humanizing-AI-writing guidance, namely the audience-context test, per-Diátaxis-type voice, and banned-construction list in CLAUDE.md § Documentation and STYLE.md § Compression. Use when asked to review, audit, or check docs (this repo's or another repo's) for AI-writing tics, wrong register, or missing antecedents, or before publishing a Tutorial/How-To/Reference/Explanation/ADR.
---

Reviews documents against evidence-backed writing rules, not house taste. See
`docs/research/writing-style/human-friendly-ai-writing-guidance.md` for the sourcing. This skill
is a checklist wrapper: it does not reimplement Diátaxis classification (`nw-documentarist`
already does that) and does not fix docs itself unless asked.

## Step 1 — Scope the target

Take an explicit path (a file, a directory, or a repo) from $ARGUMENTS. If none given, default to
the current repo's docs (`docs/`, `README.md`, any `CLAUDE.md`/`STYLE.md` this project actually
has). List every file in scope before reviewing any of it.

## Step 2 — Load the rules (mandatory, before scoring anything)

Read these two sections in full. Don't rely on ambient context: this step also has to survive
being dispatched as a subagent, which doesn't inherit this session's CLAUDE.md/STYLE.md the way an
interactive session does:

- `~/.claude/CLAUDE.md` § Documentation — audience-context test, per-type voice, banned
  constructions.
- `~/.claude/STYLE.md` § Compression — the scope boundary. It applies to session-shared prose
  (chat turns), not to the doc types below; don't cross-apply it.

If reviewing a repo other than claude-harness, these are still the rules being applied. The
target repo's own conventions (heading names, doc structure) are respected, but its prose register
is not exempt.

## Step 3 — Classify, per file

Dispatch `nw-documentarist` (`*classify` + `*detect-collapse`), one file or a batch. It already
does Diátaxis typing and collapse detection well; don't re-derive that. Embed the rule text loaded
in Step 2 into its Task prompt, so its classification and this skill's own checks are working from
the same document type, not two independent guesses.

An ADR/decision record isn't a Diátaxis type `nw-documentarist` knows. Classify those by
convention instead: frontmatter `id: DR--...` or a matching local template (this repo's own
`claude/skills/adr/SKILL.md`).

## Step 4 — Score against this harness's checks

`nw-documentarist`'s own DIVIO/collapse criteria are a separate, complementary pass. This step
adds what it doesn't cover. Per file, per its classified type:

- **Audience-context test**: does the file assume a reader who was in a conversation? Flag any
  unresolved "as discussed," "the incident," or a named person/event/decision used before it's
  defined on the page.
- **Per-type voice**: the specific rule for its type. Second person/imperative for Tutorial,
  goal-statement-first for How-To, no narrative voice for Reference, stated background for
  Explanation, antecedent-defined Context plus one decision per record for ADR.
- **Banned constructions**: the list in `CLAUDE.md` § Documentation, plus the full catalogue at
  `docs/reference/ai-writing-tics-catalogue.md` for anything CLAUDE.md's short list doesn't name.
  Weight enforcement by that catalogue's own Confidence field: High/Medium-High entries
  (sycophantic openers, markdown-leakage/list-itis, complexity-without-clarity) are real findings;
  Low-confidence single-source entries are worth a mention, not a verdict-changing violation. Read
  for the pattern, including a paraphrase, not only the literal words. Leave alone a plain factual
  contrast stating the decision made vs. the alternative rejected (e.g. an ADR title reading
  "`standard`, not `lean`"). That is scope-setting, not the rhetorical antithesis flourish this
  rule targets.
- **Bare id citations**: any reference to a decision, requirement, ADR, probe, outcome, or named
  artifact (`D-NN`, `US-NN`, `E-NN`, `O-N`, `AC-NN.N`, `ADR-NNNN`, or this target repo's equivalent)
  must carry a 2–5 word summary inline, every time it appears, not only on first mention
  (`CLAUDE.md` § Communication already states this rule for docs as well as chat; it just needs
  applying here too).

## Step 5 — Report

One table, one row per file:

| File | Type | Audience-context | Per-type voice | Banned constructions | Verdict |

Verdict: `clean` / `needs fixes` / `wrong register entirely` (e.g. an ADR written in the
Compression register). Below the table, one bullet per violation: `file:line`, what's wrong, what
to change. No violation without a fix, matching `nw-documentarist`'s own "every issue gets a fix"
rule.

## Constraints

- Review-first: do not edit files unless asked. Report and let the human decide, the same posture
  as `nw-documentarist` and this repo's `review` skill.
- Don't invent a new banned-construction per run. The list in `CLAUDE.md` is canon; if a review
  surfaces a new candidate tic, name it as a suggestion for that file, not a silent addition to
  the rule.
- Don't flag a doc for using the Compression register unless Step 2's scope boundary actually
  applies to it (a genuine chat-turn artifact, not a Tutorial/How-To/Reference/Explanation/ADR).
