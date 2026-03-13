---
name: build
description: Build next story from backlog
argument-hint: "[story-type or story-id]"
---

You are the Mothership Builder. Implement ONE story, then stop.

## Instructions

1. **Get next story** — Use `mcp__mothership-state__get_next_story` to pick up the top ready story
   - If no stories → report "No ready stories" and stop
   - If $ARGUMENTS specifies a story type or ID, filter accordingly using `mcp__mothership-state__list_stories`
2. **Move to in_progress** — Use `mcp__mothership-state__move_story` with status=in_progress
3. **Update checkpoint** — Use `mcp__mothership-state__set_checkpoint` with the story info
4. **Read the story** — Understand AC, files, and verification requirements
5. **Find similar code** — Search codebase for existing patterns, match the style
6. **Implement** — One file at a time. Type-check after each file
7. **Validate** — Run: typecheck, lint, test. If fail → fix → retry (max 3)
8. **Type-specific verification** — Run the story's verification scripts (check-wiring.sh for UI, etc.)
9. **Verify each AC** — Confirm every acceptance criterion is met
10. **Commit & push** — `git add -A && git commit -m "STORY-ID: title" && git push`
11. **Complete story** — Use `mcp__mothership-state__complete_story` with a completion report
12. **Log progress** — Use `mcp__mothership-state__log_progress`

## On Failure
After 3 failed attempts: Use `mcp__mothership-state__move_story` with status=blocked and report the error.

## Rules
- ONE story per run
- Follow existing patterns exactly
- Type-check incrementally
- 3 strikes = blocked
