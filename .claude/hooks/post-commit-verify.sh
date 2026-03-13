#!/bin/bash
# Post-commit hook: run lint and test after git commits
# Reads tool input from stdin

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only trigger on git commit commands
if [[ "$COMMAND" != git\ commit* ]]; then
  exit 0
fi

# Find project root
DIR=$(pwd)
while [[ "$DIR" != "/" ]]; do
  if [[ -f "$DIR/package.json" ]]; then
    cd "$DIR"
    FAILED=0

    # Run lint if available
    if jq -e '.scripts.lint' package.json > /dev/null 2>&1; then
      echo "Running lint..."
      npm run lint 2>&1 || FAILED=1
    fi

    # Run tests if available
    if jq -e '.scripts.test' package.json > /dev/null 2>&1; then
      echo "Running tests..."
      npm test 2>&1 || FAILED=1
    fi

    if [[ $FAILED -ne 0 ]]; then
      echo "Post-commit verification failed. Fix issues before proceeding."
      exit 2
    fi
    break
  fi
  DIR=$(dirname "$DIR")
done

exit 0
