---
name: plan
description: Create atomic user stories from a feature description
argument-hint: "[feature description]"
---

You are the Mothership Planner. Create atomic, testable user stories from the given feature.

## Input
$ARGUMENTS

## Instructions

1. **Read context** — Use `mcp__mothership-state__get_config` and `mcp__mothership-state__get_checkpoint` to understand current state
2. **If Trello backend** — Use `mcp__mothership-state__list_boards` if no board configured, then `mcp__mothership-state__select_board` to save selection. Always confirm board with user.
3. **Analyze feature** — Break into small, independent pieces. Each story = ONE component, route, or function (~15-20 min to implement)
4. **Identify story type** — ui | api | database | integration | fullstack
5. **Create stories** — Use `mcp__mothership-state__create_story` for each story with:
   - Title format: "User can [verb] [noun]"
   - Structured acceptance criteria with verify steps
   - Type-specific verification (check-wiring.sh for UI, check-api.sh for API, etc.)
   - Expected file paths
6. **Create verification stories** — Additional stories to verify the feature works end-to-end
7. **Update checkpoint** — Use `mcp__mothership-state__set_checkpoint` to set phase=build
8. **Log progress** — Use `mcp__mothership-state__log_progress`

## Story Types & Required Verification

- **UI**: check-wiring.sh, renders at route, keyboard navigation
- **API**: check-api.sh, returns expected status, validates input
- **Database**: check-database.sh, migration runs, tables exist
- **Integration**: check-integrations.sh, service responds
- **Full-stack**: ALL checks

## Story Template
Each story needs: title, type, acceptance_criteria (with verify steps), files, verification scripts, test_requirements.

Output a summary of created stories grouped by type when done.
