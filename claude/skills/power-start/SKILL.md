---
name: power-start
description: Scope a training session, presentation, talk, or coaching intervention using the POWER Start technique (Purpose, Outcome, WIIFM, Engagement, Roles & Responsibilities). Use before building the actual agenda, not instead of it.
---

Draft a POWER Start scope for: $ARGUMENTS

## Approach

POWER Start scopes the session before you plan its agenda — it answers "why does this need to
exist and what does good look like," not "what's the run of show." Build it in this order, and
expect to loop back:

1. Draft **Purpose** — rough, one paragraph.
2. Extend to **Outcome** — what's different by the end.
3. Explore **WIIFM** (What's in it for them) — from the attendee's side, not yours.
4. Iterate Purpose and Outcome once WIIFM is on the table — a WIIFM that doesn't connect to either
   usually means one of them is still wrong.
5. Draw out **Engagement** opportunities — techniques and structure, shaped by what Outcome
   actually requires.
6. Draw out **Roles & Responsibilities** — who the Engagement plan actually needs.
7. Check the whole for coherence before handing off to agenda planning.

Don't fill sections in isolation and don't treat the first draft of any section as final — the
value of POWER Start is in the loop between Purpose/Outcome and the rest, not in completing five
boxes once.

## P — Purpose

One paragraph, three sentences or fewer, plain language. States *why this needs to happen* and
the general topic. Say explicitly if a decision will be made.

**Heuristic — Purpose vs Outcome:** Purpose answers "why does this exist." Outcome answers "what's
different when it's over." If the Purpose sentence could double as a deliverable list, it's
actually an Outcome wearing Purpose's label — push it down to the next section.

## O — Outcome

The concrete, observable result attendees leave with — not the activity that produces it.

**Heuristic — output vs outcome:** "A list of options" is an output. "The team aligned on which
three options to pursue" is an outcome. If the Outcome sentence starts with a verb like "run,"
"deliver," or "cover," check whether it's actually describing the session's *activity* rather than
its *result*.

**Gentle validation:** would this Outcome make someone want to attend, on its own, with no other
context? If not, it's too vague to plan Engagement against yet.

## W — WIIFM (What's in it for them)

Map this from the attendee's existing goals, not the organiser's. What are they already trying to
achieve, and how does this session move that forward? One useful framing: what do they miss out on
if they skip it?

**Gentle validation:** if the audience isn't homogeneous (sponsor vs. practitioner vs. skeptic),
WIIFM likely differs by segment — don't force one line to cover all of them. Name the segments if
they diverge.

## E — Engagement

What keeps this from being a passive session. Match the technique to what the Outcome needs, not
to whatever's familiar:

- **Structured delivery** (teaching a concept): TBR/4Cs — Connections, Concepts, Concrete Practice,
  Conclusions.
- **Divergent / idea generation:** 25/10 crowdsourcing, Liberating Structures' 1-2-4-All.
- **Convergent / prioritisation:** dot voting.
- **Remote or hybrid:** Miro (or equivalent) for anything that would be a whiteboard in person;
  decide this explicitly rather than defaulting to slides + Q&A.
- **Always:** a visible agenda with timings, a parking lot for off-topic threads, and a named place
  actions and decisions get captured.

**Gentle validation — prep ratio:** roughly one hour of prep per hour of session. If none has been
budgeted, flag it rather than let it default to zero.

**Gentle validation — pre-reads:** is there anything attendees should read before the session, so
session time isn't spent on context-setting that could've happened async?

## R — Roles & Responsibilities

Who does what, before, during, and after:

- **Facilitator** — running the session vs. **co-facilitator** — if the facilitator also needs to
  participate in the content, that's double duty; flag it and suggest a co-facilitator.
- **Sponsor** — who opens/closes, or lends authority to the outcome landing.
- **Scribe** — who's capturing actions and decisions (should match the "named place" from
  Engagement).
- **Subject matter experts** — named, not assumed.
- **Audience expectations** — for each attendee group: their *role* in the session (contribute /
  inform / decide), relevant *domain* expertise, and what *accountability* they're expected to
  carry afterward. An attendee who doesn't know which of these three applies to them usually
  disengages.

## Iterate

Before calling this done, check:

- Does the Engagement plan actually serve the stated Outcome, or did it default to a comfortable
  technique regardless of what the Outcome needs?
- Do the Roles cover what Engagement requires (e.g. breakout groups need enough co-facilitators to
  staff them)?
- Does WIIFM still track against the final Purpose/Outcome, or did those move without WIIFM
  catching up?

## Output format

Produce a draft in this structure, ready to save as markdown:

```markdown
---
session: <name>
date: YYYY-MM-DD
type: <training | presentation | talk | coaching intervention | other>
---

# POWER Start — <session name>

## Purpose

<one paragraph, ≤3 sentences>

## Outcome

<concrete, observable result>

## WIIFM

<per-segment if the audience isn't homogeneous>

## Engagement

<techniques, prep ratio, pre-reads, agenda/parking-lot/actions plan>

## Roles & Responsibilities

<facilitator, co-facilitator, sponsor, scribe, SMEs, audience expectations by group>
```

Use today's date. Suggest a session type based on the topic if not stated.

## Phase 2 — Save the scope

Save the drafted scope as markdown, the same way `/adr` and `/story` save their outputs — otherwise
this scoping work exists only in chat and is gone once the conversation ends.

1. **Find the scopes directory.** Look for an existing one — commonly `docs/power-starts/` or
   `docs/sessions/`. If none exists, create `docs/power-starts/`, or ask where the user keeps
   session-planning artifacts.
2. **Derive a slug** from the session name (kebab-case) and write the file as
   `YYYY-MM-DD--<slug>.md` — dated, because a POWER Start scopes one specific session instance, not
   a living backlog entry.
3. **Confirm**: "POWER Start for `<session name>` saved to `<path>`. Hand this to agenda planning
   next — POWER Start sets the scene, it doesn't sequence the session."
