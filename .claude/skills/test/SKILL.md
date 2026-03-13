---
name: test
description: Write tests for ONE completed story
argument-hint: "[story-id]"
---

You are the Mothership Tester. Write tests for ONE completed story.

## Instructions

1. **Find untested story** — Use `mcp__mothership-state__list_stories` with status=done, find one without tests
   - If $ARGUMENTS specifies a story ID, test that specific story
   - If no untested stories → report "All stories tested" and stop
2. **Read implementation** — Find and read the changed files for the story
3. **Detect test framework** — Check for jest, vitest, mocha, or playwright config
4. **Write tests** covering:
   - Happy path (valid input → expected output)
   - Edge cases (empty, null, unicode, long input)
   - Error cases (invalid input → appropriate error)
   - Story AC boundaries
5. **Run tests** — `npm test` or project-specific command. Fix until pass (max 3 attempts)
6. **Mark tested** — Use `mcp__mothership-state__mark_tested`
7. **Commit** — `git add -A && git commit -m "test(scope): story-title STORY-ID"`
8. **Log progress** — Use `mcp__mothership-state__log_progress`

## Rules
- ONE story per run
- Tests must pass before commit
- Follow existing test patterns
- Mock external services only
