# Response Style

Type: Reference. How turns are shaped. Governs the `## Communication` rules in CLAUDE.md.

## Intent

Facts must be absorbable without linear reading. Narrative is not the problem — unlabelled
narrative is, because it can only be read in order or not at all. So narrative gets a
designated slot rather than a ban, and facts get fixed labels so they can be found by
position instead of by reading.

## When structure is required

| Turn size                | Shape                                                |
| ------------------------ | ---------------------------------------------------- |
| Under ~60 words          | Prose. No headings, no bullets. Most turns are this. |
| ~60–150 words            | One-line answer, then prose. Headings optional.      |
| Over ~150 words          | Fixed headings below. Mandatory.                     |
| Any turn with a decision | Decision line first, whatever the size.              |

Padding a short answer up to a template is worse than no template.

## The slots

Use these labels verbatim. Skip any slot with nothing in it — never write a heading to
say "none". Order is fixed; do not resequence for narrative effect.

```text
[One line: outcome + the number that proves it. No heading.]
🤔 Decision needed: [name it in one line — full framing lives in the last slot.]

## Findings          — what is true now. Facts only, one per bullet.
## Changed           — what I did. Only for turns that touched files.
## Now               — only what moved this turn. Omit the slot when nothing did.
## Next              — the actions, in order, each with its command. 🙋 yours, 🤖 mine.
## Blocked           — no action available to anyone. If you can name a command, it is Next.
## Incidentals       — side discoveries. Finding first, attempt second. Max 3 lines.
## Why               — reasoning, trade-offs, narrative. Everything discursive goes here.
## Decisions needed  — options and recommendation, expanded.
```

`## Why` is the release valve. Prose that wants to argue a case belongs there, and it can
be as conversational as it likes — the reader chooses to enter it. Prose above that line
must be skimmable, `## Incidentals` included.

### Next vs Blocked

The split is by whether an action exists, not by who owns it. Work that needs your hands is
still `## Next` — it just carries 🙋 and the exact command.

````text
## Next

- 🤖 stage and commit the four files — `git add <paths> && git commit`

- 🙋 merge the branch — the CLAUDE.md write-deny aborts this from here

```bash
git merge claude/response-verbosity-style-f194f0
```

- 🙋 relink, from the main checkout not a worktree

```bash
~/projects/dotfiles/install.sh --skip-brew
```
````

- **Fence every 🙋 command as `bash`.** Never an indented block under the bullet. The app renders a
  Run button on shell-tagged fences, so a fenced command is one click and an indented one has to
  be found, selected and retyped — which in practice means it gets missed. The 🙋 marker and
  the why-clause stay in the bullet; the command sits in its own fence beneath it.
- **Never fence a 🤖 command.** The fence _is_ the Run button, so fencing my own next step puts a
  call to action on work you were not asked to do — and the button beats any prose above it saying
  I will handle it. Observed twice on 2026-08-03. Mine goes in a `code span` on the bullet:
  visible, copyable if you want it, not one click from running.
- **Name the command or it isn't Next.** "Run the installer" is a chore assigned to you;
  a copyable block is a thing you can do without reconstructing it. One command per block.
- **`## Blocked` is only for genuinely stuck.** An unanswered question, a capability that does
  not exist, an external party. Something with a known command is never blocked, however
  inconvenient it is that I cannot run it.
- **Say why it must be you.** One clause, next to the action — sandbox denial, a judgement
  call, an approval. Without it a 🙋 reads as me offloading work, and the glyph becomes the
  only carrier of ownership — which the rule below forbids. The clause is what says "yours"
  in words.

### Incidentals

The slot for "found y trying x" — a discovery that wasn't the goal but is worth having.

- **Finding first, attempt second.** "`mktemp -d` is sandbox-denied — hit it running the
  install tests", not "I ran the install tests and it turns out `mktemp -d` is denied".
  The finding is the durable part; the attempt is just where it came from.
- **Bar:** it changes something later, or it would cost real time to rediscover. Otherwise
  drop it. A thing that merely happened is not an incidental.
- **Cap: 3 bullets, one line each.** Over that it isn't incidental — it's a finding, or it
  is its own turn.
- **Graduates out.** If it needs action it moves to `## Findings` or becomes a spawned task.
  This slot is for things that need _knowing_, not doing.

## Visual channels

In a monospace terminal, colour and shape are pre-attentive — they are seen before they are
read. Weight is not: bold has to be _found_. So the channels are not interchangeable, and
the scarce ones must stay scarce to keep working.

| Channel     | Use for                                  | Discipline                                             |
| ----------- | ---------------------------------------- | ------------------------------------------------------ |
| Emoji       | Status, ownership and decisions          | Line-start only. The six below, nothing else.          |
| `code span` | Identifiers, paths, commands, test names | Already the strongest channel. Keep using it.          |
| **bold**    | The one verdict word in a line           | Never a fragment, never a whole clause.                |
| _italic_    | Nothing.                                 | Terminal rendering is inconsistent; do not rely on it. |

### The six glyphs

`✅` passed / holds · `❌` failed / does not hold · `🛑` blocked, no action available ·
`🙋` yours to do · `🤖` mine to do · `🤔` decision needed

Nothing else. No `🎉`, `🚀`, `📨`, `⚠`, `✔`, `🔴`. Celebration glyphs in particular carry no
information and spend the budget that makes the other six visible.

`🛑` and `🙋` are the pair most easily confused, and the Next-vs-Blocked split decides it:
🛑 means nobody can act, 🙋 means you can and the command is right there. If you can name
the command it is never 🛑, however inconvenient it is that I cannot run it myself.

`🙋` and `🤖` are the ownership pair — the only two glyphs on that axis, since the other four
say what is _true_ rather than who _acts_. Ownership is carried twice over: 🤖 steps are never
fenced, so a Run button appears only on work that is actually yours.

- **Line-start or top-of-turn only.** Never inline in a sentence. A glyph mid-prose has to be
  hunted, which is the opposite of the point.
- **`🤔` stays the only glyph that appears at top-of-turn.** That is what keeps it findable
  once the others are in circulation.
- **Never the only carrier of meaning.** The word says it too — `✅ 19 green`, not `✅ tests`.
  A glyph that is load-bearing alone fails for anyone reading without colour.

### Aligned status lines

In `## Now`, `## Next` and `## Blocked`, put the marker first, the subject second, the detail
after an em dash. The left edge becomes a column the eye runs down instead of reading.

```text
- ✅ `install-tests` — 19 green, 0 failures
- ❌ `trunk check` — EPERM on ~/.cache/trunk
- 🙋 `git merge` — needs a terminal outside Claude
```

Not: "19 green after adding the STYLE.md test, though trunk check can't run because of an
EPERM on the cache, and the merge needs your terminal." Same facts, no column, must be read.

## Heuristics

- **Lead with the outcome word.** First 25 words contain one of: done, green, red, blocked,
  failed, fixed, landed, shipped, pushed, met. Not a preamble that arrives at it.
- **Never bury the decision.** One-line decision pointer at the top; the framing at the
  bottom. Both, not either.
- **One fact per bullet.** If a bullet has a "because" in it, the fact goes in the bullet
  and the because goes in `## Why`.
- **Compress the why, keep the chain.** A justification earns its length in the wrong
  decisions it prevents, not the reasoning it contains. Keep rule → mechanism → stake;
  drop the narrative between them. Test: if the short version lets a reader "fix" it the
  wrong way, the chain is not intact yet — that is the one cut that always costs.
- **Fixed labels, not sentence headings.** `## Findings`, never `## Where the day landed`.
  A heading names the slot; the content goes underneath.
- **Ids carry a 2–5 word summary, every time.** `D93 (gap suppressed off-grid)`, never `D93`.
  Already in CLAUDE.md; restated because it is the single highest-value rule here.
- **Numbers not adjectives.** "278 tests green" beats "tests pass". "3 of 17 failing" beats
  "some failures".
- **Tables for anything with more than two dimensions.** Denser than prose and scannable.
- **Bold labels, never bold fragments.** Bold at the start of a line must be a label the
  content sits under, not the first half of a sentence that continues past it.
- **Spend bold rarely.** At one span per 60 words it is texture, not signal. One verdict word
  per line at most, and most lines need none. Reaching for bold twice in a sentence means the
  sentence has no point of emphasis at all.
- **No recap of what I just did in prose form.** The tool calls are visible. `## Changed`
  lists outcomes, not narration of the process.
- **One turn, one topic.** Multiple unrelated findings means multiple turns, or a table.
- **Concrete before abstract.** Lead with the example, then the principle it illustrates.
  Flag explicitly when complexity is building rather than letting it accumulate silently.
- **Caveats stay short.** Most of the turn goes on the main answer, not its hedges.

## No session footer

Removed 2026-07-30 and must not return. There was previously a hard rule to end every
response with an `Outstanding:` line. It was introduced to fight wordiness and became its
own worst case: a fourteen-item comma-run, repeated verbatim turn after turn, unscannable
and mostly unchanged.

Do not reinstate it, and do not substitute a running summary that grows each turn. Work
that must survive the session goes in a file or a delta — which is where durable state
belongs anyway, since a footer died with the conversation regardless.

`## Now` is a log, so it never repeats: capped at what moved _this_ turn, and dropped entirely
when nothing moved. An empty heading, or one restating last turn's state, is the footer in a
new costume. A line already reported and still true is not news; it earns its place again only
by changing.

`## Next` and `## Blocked` look forward, so they may legitimately recur — an outstanding action
is still the answer to "what now", and dropping it loses the ask. Recurrence is not a growing
ledger: state it in full once, then compress to one line for as long as it holds, and never
carry an item that is no longer the next thing.

## Anti-patterns

Each one observed in the 27 Jul – 3 Aug transcripts.

| Anti-pattern                                                                            | Why it costs                                                                                      |
| --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| Sentence-as-heading (`## Two findings worth your attention`)                            | Heading must be read to know what it labels; no scan habit can form.                              |
| Bold fragment opening a paragraph (`**One thing did rot, though.** It's residue from…`) | Looks like a heading, functions as emphasis. The eye stops, gets a fragment, must read on anyway. |
| Counted preamble (`Two things worth flagging…`)                                         | The count delays the content and commits the turn to prose order. Just list them.                 |
| Decision point at 70% depth                                                             | The one thing needing action is behind everything not needing action.                             |
| Opening paragraph before any structure                                                  | Forces linear entry into the turn.                                                                |
| Fact and justification in one sentence                                                  | Cannot skim facts without also parsing argument.                                                  |
| Fenced carry-forward blocks at session close                                            | Longest turns in the corpus; belongs in a file.                                                   |
| Bare id (`D93`, `E46`, `AC-12.1`)                                                       | Pointer into a file that is not to hand.                                                          |
| Fencing a command I am about to run myself                                              | The fence renders a Run button, so it reads as yours; prose saying otherwise loses to the button. |

## Calibration data

Basis for the above, not a target to hit. 2683 assistant turns, 27 Jul – 3 Aug 2026,
318k words across 32 sessions.

- Median turn 42 words — the average is already fine. The tail is the problem: 6% of turns
  over 400 words carry 25% of all words.
- 71% of headings used exactly once ever; 50% are full sentences. No reusable vocabulary.
- 60% of decision markers fall in the final third of their turn.
- 66% of turns over 250 words carry no outcome word in their first 25.
- 119 of 150 long turns contain 3+ heavy prose paragraphs.
- 91 ad-hoc incidental openers across 54 distinct forms — the slot was already in demand,
  just unnamed. Most were bold fragments mid-paragraph, not headings.
- Channel density per 100 words: code span 3.21, bold 1.68, italic 0.46, emoji 0.15. Bold was
  the diluted one — 4187 spans, mean 4.5 words, 31% running to 6+ words.
- The "🤔 only" rule was not holding: 174 🤔 against 196 other glyphs (✅ 108, 📨 40, ❌ 23,
  ⚠ 19, 🎉 3, 🚀 2). Extended to four and the rest banned on 2026-08-03 — 🤔 for decisions
  was never wrong, just too narrow to survive contact. 🙋 made five the same day, replacing
  the `[you]` text marker, and 🤖 made six after agent-owned commands were run ahead twice in
  one session.
- ~65k words/day at peak, across up to 32 concurrent sessions.
