---
name: verify
description: Run verification checks on the project
argument-hint: "[type: ui|api|database|integration|all]"
---

Run type-specific verification checks. Do NOT modify any code.

## Instructions

1. Determine type from $ARGUMENTS (default: all)
2. Run appropriate scripts:
   - **ui**: `./scripts/check-wiring.sh src/`
   - **api**: `./scripts/check-api.sh`
   - **database**: `./scripts/check-database.sh`
   - **integration**: `./scripts/check-integrations.sh`
   - **all**: `./scripts/verify-all.sh`
3. Also run standard checks: `npm run typecheck && npm run lint && npm run test`
4. Report pass/fail for each check
5. Log results via `mcp__mothership-state__log_progress`

## Rules
- Do NOT modify any files
- Report results clearly with pass/fail per check
