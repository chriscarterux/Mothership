---
name: onboard
description: Scan project and create codebase.md for AI context
argument-hint: "[project-path]"
---

Scan the project and generate a `.mothership/codebase.md` file that gives AI agents the context they need.

## Instructions

1. **Scan structure** — Read package.json, tsconfig.json, directory layout
2. **Identify stack** — Framework, language, database, deployment
3. **Map patterns** — Find routing patterns, component patterns, API patterns, test patterns
4. **Document conventions** — File naming, import style, state management, error handling
5. **Find scripts** — Available npm scripts, their purposes
6. **Check config** — Environment variables needed, external services used

## Output: `.mothership/codebase.md`
```markdown
# Codebase: [project-name]

## Stack
- Framework: [e.g., Next.js 14]
- Language: TypeScript
- Database: [e.g., PostgreSQL via Prisma]
- Deployment: [e.g., Vercel]

## Structure
[directory tree with descriptions]

## Patterns
### Components: [pattern description]
### API Routes: [pattern description]
### Database: [pattern description]

## Conventions
- File naming: [kebab-case, etc.]
- Imports: [absolute paths, barrel exports, etc.]
- State: [Zustand, Redux, Context, etc.]

## Scripts
| Command | Purpose |
|---------|---------|

## Environment
| Variable | Purpose | Required |
|----------|---------|----------|
```

Save to `.mothership/codebase.md` and report summary.
