---
globs:
  - ".mothership/**"
---

# State Backend Rules

- Always use MCP tools (`mcp__mothership-state__*`) for state operations — never raw file I/O on stories.json or checkpoint.md
- Never assume which backend is active — always check via `get_config` first
- Confirm board selection before creating stories when using Trello
- Use `get_checkpoint` to understand current phase before making state changes
- When creating stories, always include structured acceptance criteria with verify steps
