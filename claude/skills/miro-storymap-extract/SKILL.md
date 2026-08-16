---
name: miro-storymap-extract
description: Extract a Miro story-map SVG export into compact structured JSON (journeys → steps → stories across release swimlanes) by running a bundled script — so Claude reasons over the board structure without spending tokens parsing the raw SVG.
---

Run the bundled extractor to turn a Miro story-map SVG export into structured JSON. Invoke the
script and read its stdout — never read the SVG or the script source into context (that is the
whole point: the token cost is the small JSON output, not the large geometry-/style-dominated SVG).

## When to use

- You have a Miro **story-map** SVG export and need its structure as data: which stories sit under
  which step and journey, and in which release swimlane.
- The board follows the standard story-map layout (see Structure). Arbitrary diagrams are out of scope.

## How to invoke

From this skill's directory:

```bash
node scripts/extract.mjs <path-to-svg>
```

JSON on stdout (shape):

```json
{
  "journeys": [{ "name": "Session Management", "steps": [{ "name": "Session" }] }],
  "swimlanes": ["Walking Skeleton", "MVP", "Unplanned cards"],
  "cards": [{ "journey": "...", "step": "...", "swimlane": "...", "title": "...",
             "jira_key": "AVA-1234", "commit_ref": "94fe8d3 (#191)", "status": "Done",
             "x": 120, "y": 200 }],
  "counts": { "journeys": 12, "steps": 19, "swimlanes": 3, "cards": 103 }
}
```

## Structure (how the board is read)

Position — not colour — defines the tiers (card colours are changeable and are ignored):

- **Row 1 = journeys**, **row 2 = steps** (columns), **rows 3+ = stories**. A story belongs to the
  step above it (nearest by x); a step belongs to the journey spanning its x; a story's journey is
  its step's journey.
- **Swimlanes = release bands**, ordered top→bottom = **earliest release first**. The bottom lane
  (e.g. "Unplanned cards") is unscheduled stories awaiting prioritisation.
- Each card's `status` / `jira_key` / `commit_ref` / cleaned `title` is parsed from its **text**
  (Miro exports cards as `<foreignObject>` HTML); absolute `x,y` come from composing the SVG
  transform stack.

## Contract

- **Input:** path to a Miro story-map SVG export (UTF-8).
- **Output (stdout):** `{ journeys[], swimlanes[], cards[], counts }` as above. Cards are flat and
  denormalised (each carries journey/step/swimlane); `journeys[]`/`swimlanes[]` are the axis
  definitions in left→right / earliest-first order.
- **Counts are derived** from the data — never hardcoded.
- **Deterministic:** identical input → identical output. No network, no dependencies (`node:fs` only).
- **Errors:** a missing path argument exits `2`; an unreadable file surfaces the Node error (non-zero).

## Limitations

- Step→journey rollup is by x-span (a journey owns `[its x, the next journey's x)`); a journey with
  no step in its span resolves to 0 steps. Precision is bounded by header x-alignment.
- The title heuristic is a faithful port of the reference `extract.py`: a jira key can remain in the
  `title` when no `- <sha>` precedes it in the card text.

## Status

DELIVER — real Miro-export parser: a faithful JS port of the validated `extract.py` plus the
journey tier the Python flattens. Validated against a live export (12 journeys / 19 steps /
103 stories / 3 swimlanes). Acceptance test: `tests/skills-tests.sh`.
