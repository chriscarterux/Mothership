#!/bin/bash
# Pre-tool-use hook: block dangerous bash commands
# Reads tool input from stdin, blocks destructive operations

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# Block patterns
BLOCKED_PATTERNS=(
  "rm -rf /"
  "rm -rf ~"
  "rm -rf \$HOME"
  "git push --force origin main"
  "git push --force origin master"
  "git push -f origin main"
  "git push -f origin master"
  "DROP TABLE"
  "DROP DATABASE"
  "TRUNCATE TABLE"
  "git reset --hard origin/main"
  "git reset --hard origin/master"
  "git clean -fd"
  "> /dev/sda"
  "mkfs."
  ":(){:|:&};:"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if [[ "$COMMAND" == *"$pattern"* ]]; then
    echo "BLOCKED: Command contains dangerous pattern '$pattern'"
    echo "This command could cause irreversible damage. Please use a safer alternative."
    exit 2
  fi
done

exit 0
