#!/bin/bash
# x - The entire system in 60 lines. No prompt files. No config.
set -e

# Auto-detect AI
AI=$(command -v claude || command -v gemini || command -v codex || command -v opencode || echo "")
[[ -z "$AI" ]] && echo "No AI found" && exit 1
AI=$(basename "$AI")

# State = git. Stories = TODOs. That's it.
TODO_FILE="TODO.md"

# What needs doing? (priority order)
next() {
    # Uncommitted work → commit
    [[ -n $(git status --porcelain 2>/dev/null) ]] && echo "commit" && return

    # Tests failing → fix
    (npm test --if-present || pytest -q || go test ./... || true) 2>/dev/null | grep -qi "fail" && echo "fix" && return

    # Unchecked TODOs → build
    [[ -f "$TODO_FILE" ]] && grep -q "^\- \[ \]" "$TODO_FILE" && echo "build" && return

    # No TODOs → plan
    [[ ! -f "$TODO_FILE" ]] && echo "plan" && return

    # All done
    echo "done"
}

# One-line prompts. That's all the AI needs.
prompt() {
    case "$1" in
        plan)   echo "Create $TODO_FILE with tasks. Format: - [ ] Task. Be specific." ;;
        build)  echo "Do the next unchecked item in $TODO_FILE. Mark it [x] when done. Commit." ;;
        fix)    echo "Tests are failing. Fix them. Commit when green." ;;
        commit) echo "Review uncommitted changes. Test. Commit if good." ;;
        done)   echo "All tasks complete. Final review. Any gaps?" ;;
    esac
}

# Run
ACTION=$(next)
PROMPT=$(prompt "$ACTION")

# Add goal if provided
[[ -n "$*" ]] && PROMPT="Goal: $*. $PROMPT"

echo "[$AI] $ACTION"
case "$AI" in
    claude)   claude --print -p "$PROMPT" ;;
    gemini)   gemini "$PROMPT" ;;
    codex)    codex "$PROMPT" ;;
    opencode) opencode "$PROMPT" ;;
esac
