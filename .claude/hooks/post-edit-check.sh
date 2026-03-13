#!/bin/bash
# Post-edit hook: typecheck after editing TypeScript source files
# Reads tool input from stdin, checks if edited file is .ts/.tsx in src/

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only typecheck for source TypeScript files
if [[ "$FILE" == */src/*.ts ]] || [[ "$FILE" == */src/*.tsx ]]; then
  # Find project root (nearest package.json)
  DIR=$(dirname "$FILE")
  while [[ "$DIR" != "/" ]]; do
    if [[ -f "$DIR/package.json" ]]; then
      # Check if typecheck script exists
      if jq -e '.scripts.typecheck' "$DIR/package.json" > /dev/null 2>&1; then
        cd "$DIR" && npm run typecheck 2>&1
        exit $?
      fi
      break
    fi
    DIR=$(dirname "$DIR")
  done
fi

exit 0
