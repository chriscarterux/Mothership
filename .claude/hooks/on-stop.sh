#!/bin/bash
# Stop hook: update progress.md when session ends
# Uses file I/O directly (not MCP — hooks must be fast)

# Find .mothership directory
DIR=$(pwd)
while [[ "$DIR" != "/" ]]; do
  if [[ -d "$DIR/.mothership" ]]; then
    MOTHERSHIP_DIR="$DIR/.mothership"
    break
  fi
  DIR=$(dirname "$DIR")
done

if [[ -z "$MOTHERSHIP_DIR" ]]; then
  exit 0
fi

CHECKPOINT="$MOTHERSHIP_DIR/checkpoint.md"
PROGRESS="$MOTHERSHIP_DIR/progress.md"

if [[ ! -f "$CHECKPOINT" ]]; then
  exit 0
fi

# Read current phase
PHASE=$(grep -m1 '^phase:' "$CHECKPOINT" 2>/dev/null | sed 's/^phase:[[:space:]]*//')
PROJECT=$(grep -m1 '^project:' "$CHECKPOINT" 2>/dev/null | sed 's/^project:[[:space:]]*//')

# Append stop entry to progress
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cat >> "$PROGRESS" << EOF

### $TIMESTAMP
**Phase:** ${PHASE:-unknown}
**Project:** ${PROJECT:-unknown}
**Action:** Session ended

EOF

# Rotate progress.md if > 500 lines
if [[ -f "$PROGRESS" ]]; then
  LINES=$(wc -l < "$PROGRESS")
  if [[ $LINES -gt 500 ]]; then
    ARCHIVE="$MOTHERSHIP_DIR/progress-$(date +%Y-%m-%d).md"
    head -n $((LINES - 200)) "$PROGRESS" > "$ARCHIVE"
    tail -n 200 "$PROGRESS" > "$PROGRESS.tmp"
    mv "$PROGRESS.tmp" "$PROGRESS"
  fi
fi

exit 0
