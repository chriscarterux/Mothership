---
name: status
description: Show current Mothership project status
---

Show the current state of the Mothership project.

## Instructions

1. Read config: `mcp__mothership-state__get_config`
2. Read checkpoint: `mcp__mothership-state__get_checkpoint`
3. List all stories: `mcp__mothership-state__list_stories`
4. Count by status: ready, in_progress, done, blocked
5. Show git branch and recent commits

## Output Format
```
Project: [name]
Phase: [current] → [next]
Branch: [branch]
Backend: [trello/linear/local]

Stories:
  Ready:       N
  In Progress: N
  Done:        N
  Blocked:     N
  Total:       N

Recent Activity: [last 3 progress entries]
```
