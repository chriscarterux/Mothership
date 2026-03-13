---
globs:
  - "scripts/*.sh"
---

# Verification Script Rules

- Safe .env parsing: strip quotes and CRLF using BASH_REMATCH or parameter expansion
- Use `lsof` not `ss` for port checking (macOS compatibility)
- Use `stat -f` fallback for BSD compatibility (macOS)
- Always use `set -e` at the top of scripts
- Exit 0 for pass, non-zero for fail
- Output clear pass/fail messages with details on failure
- Don't require interactive input — scripts must be fully automated
