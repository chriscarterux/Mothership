---
name: quick-check
description: Fast sanity check — catches 80% of problems in 60 seconds
---

Run fast sanity checks. Do NOT fix anything.

## Instructions

1. Check for empty handlers: `grep -rn "onClick={}\|onSubmit={}\|() => {}" src/ 2>/dev/null`
2. Run build: `npm run build` (if package.json exists)
3. Run tests: `npm test` (if package.json exists)
4. Show git status: `git status --short`

## Output
Report pass/fail count. Quick and concise.
