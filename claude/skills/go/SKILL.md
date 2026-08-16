---
name: go
description: Approve the current plan or proposal and proceed with execution. Use as a low-friction signal when you want Claude to continue without re-explanation.
disable-model-invocation: true
---

The plan or proposal has been approved. Proceed with the next step.

## Instructions

1. Call `TaskList` — if there are open tasks, continue from the lowest-numbered one that is pending
   and unblocked
2. If a specific proposal was just made in conversation, execute it now
3. Do not re-explain the plan — just act
4. Keep task state current as you go: `in_progress` before starting, `completed` only when the work
   genuinely is. Never mark complete with tests failing or the implementation partial
5. Stop and surface any decision points or blockers rather than resolving them silently — when
   blocked, create a task describing what needs resolving rather than working around it
