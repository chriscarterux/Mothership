#!/bin/bash
# Install Mothership status line for Claude Code
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STATUSLINE_SCRIPT="$SCRIPT_DIR/statusline/statusline-command.sh"
SETTINGS_FILE="$HOME/.claude/settings.json"

if [ ! -f "$STATUSLINE_SCRIPT" ]; then
  echo "Error: statusline-command.sh not found at $STATUSLINE_SCRIPT"
  exit 1
fi

# Ensure jq is available
if ! command -v jq &> /dev/null; then
  case "$(uname)" in
    Darwin) INSTALL_HINT="brew install jq" ;;
    Linux)  INSTALL_HINT="sudo apt install jq  # or: sudo yum install jq" ;;
    *)      INSTALL_HINT="see https://jqlang.github.io/jq/download/" ;;
  esac
  echo "Error: jq is required. Install with: $INSTALL_HINT"
  exit 1
fi

# Ensure ~/.claude/ exists
mkdir -p "$HOME/.claude"

# Create settings.json if it doesn't exist
if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{}' > "$SETTINGS_FILE"
fi

# Set the statusLine config using jq
jq --arg cmd "bash $STATUSLINE_SCRIPT" \
  '.statusLine = {"type": "command", "command": $cmd}' \
  "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"

chmod +x "$STATUSLINE_SCRIPT"

echo "Status line installed."
echo "  Script: $STATUSLINE_SCRIPT"
echo "  Config: $SETTINGS_FILE"
echo ""
echo "Restart Claude Code to see the gold status bar."
