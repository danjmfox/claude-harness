---
name: done
description: Session close skill — retrospective scan, carry-forward list, friction findings, and two copy-ready prompts (process improvement + task follow-on)
user-invocable: true
disable-model-invocation: true
---

When invoked, scan this conversation and produce the sections below in order. No clarifying questions — infer what you can and state any uncertainty inline.

## Session close

State:
- The goal that was being worked on (inferred from the conversation)
- Progress status: **met** | **partially met** | **blocked**
- One sentence summary of what was achieved or where work stopped

## Carry forward

List unimplemented ideas, deferred decisions, or open threads from this session. Each item on one line with enough context to act on in a new session.

If nothing to carry forward: state `No items to carry forward.`

```
- [item]: [one-line context]
```

## Process review

Scan the conversation for friction events: rework, errors, incorrect commands, misunderstandings, surprises, wasted effort, things that had to be undone.

If none: state `No friction identified this session.`

If findings exist: list 1–5. No padding. Do not omit real friction. No generic advice — every finding must be specific to what happened in this session.

Format each finding as three labelled lines:

```
behaviour: [what happened — specific to this session]
impact: [cost — time lost, rework required, confusion caused]
opportunity: [concrete improvement — what to add, change, stop, or record]
```

## Process improvement prompt

Generate a fenced code block containing a prompt that captures the process opportunities from this session. Ready to paste into a CLAUDE.md pull request, a new improvement session, or a skill file update.

If no friction was identified, the block should say so explicitly rather than being empty.

```
[process improvement prompt — ready to copy]
```

## Follow-on prompt

Generate a second fenced code block: a self-contained prompt to resume or continue work in a fresh chat. Dan must be able to paste it without editing.

Must include:
- Project name and current state (branch if relevant, what was just done, what is clean or broken)
- Next story or outstanding blocker (one sentence)
- Decisions already made that the next session should not re-litigate
- Relevant file pointers

Adapt this format to the session's context:

```
Project: [name] — [one-line description]
Stack: [relevant tools, languages, frameworks]
State: [branch / what was just done / what is in progress or blocked]
Next: [next story, task, or blocker]
Key decisions: [decisions made — do not re-litigate]
Context files: [files worth reading to orient]
Start with: [next story or task].
```

## nWave feature hint (when applicable)

If `docs/feature/` exists in the current working directory and contains active project directories, find the most recently modified one and append one line to the follow-on prompt block:

```
Active nWave feature: [feature-id] — run /nw-continue to resume at [most recent wave].
```

Detect the most recent feature directory with:
```bash
find docs/feature/ -maxdepth 1 -mindepth 1 -type d 2>/dev/null | xargs -I{} stat -f "%m %N" {} 2>/dev/null | sort -rn | head -1 | awk '{print $2}' | xargs basename
```

If `docs/feature/` does not exist or is empty, omit this line entirely.

## Constraints

- Works regardless of whether plan mode or a task list was used in this session
- Does not write any files — output is plain text in this chat only
- Does not ask clarifying questions
- Output must be scannable in under 30 seconds for a simple session; keep it proportionate
- The two fenced code blocks use plain fences (no language tag) so Claude Code renders them as copyable blocks
- Never fabricate friction — if the session was clean, say so explicitly
- Cap findings at five; prioritise by impact, not recency
