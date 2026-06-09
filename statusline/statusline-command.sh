#!/bin/bash
# Claude Code Status Line - gold yellow
# Shows: [repo] path | model | context% | $cost | worktree | mothership: phase -> next
INPUT=$(cat)

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
MODEL=$(echo "$INPUT" | jq -r '.model // empty')
CONTEXT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // empty' | cut -d. -f1)
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // empty')
WORKTREE=$(echo "$INPUT" | jq -r '.worktree.name // empty')
AGENT=$(echo "$INPUT" | jq -r '.agent.name // empty')

if [ -n "$CWD" ] && [ -d "$CWD" ]; then
  REPO=$(cd "$CWD" && git -c gc.auto=0 rev-parse --show-toplevel 2>/dev/null | xargs basename 2>/dev/null)
  GIT_ROOT=$(cd "$CWD" && git -c gc.auto=0 rev-parse --show-toplevel 2>/dev/null)
fi

# Mothership phase detection (works for any git repo)
MOTHERSHIP_PHASE="not configured"
if [ -n "$GIT_ROOT" ] && [ -f "$GIT_ROOT/.mothership/checkpoint.md" ]; then
  CHECKPOINT="$GIT_ROOT/.mothership/checkpoint.md"
  # Support both "## Phase:" and "phase:" formats
  CURRENT_PHASE=$(grep -m1 -E '^(## )?[Pp]hase:' "$CHECKPOINT" 2>/dev/null | sed 's/^## Phase:[[:space:]]*//;s/^phase:[[:space:]]*//' | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
  if [ -n "$CURRENT_PHASE" ]; then
    PHASES="plan build test review deploy done"
    PHASE_LIST=($PHASES)
    NEXT_PHASE=""
    for i in "${!PHASE_LIST[@]}"; do
      if [ "${PHASE_LIST[$i]}" = "$CURRENT_PHASE" ]; then
        NEXT_IDX=$((i + 1))
        if [ $NEXT_IDX -lt ${#PHASE_LIST[@]} ]; then
          NEXT_PHASE="${PHASE_LIST[$NEXT_IDX]}"
        fi
        break
      fi
    done
    if [ -n "$NEXT_PHASE" ]; then
      MOTHERSHIP_PHASE="${CURRENT_PHASE} -> ${NEXT_PHASE}"
    else
      MOTHERSHIP_PHASE="$CURRENT_PHASE"
    fi
  fi
fi

GOLD='\033[38;5;220m'
RESET='\033[0m'

PARTS=""
if [ -n "$REPO" ]; then
  PARTS="[$REPO]"
fi

SHORT_PATH=$(echo "$CWD" | sed "s|^$HOME|~|")
if [ -n "$SHORT_PATH" ]; then
  PARTS="$PARTS $SHORT_PATH"
fi

if [ -n "$MODEL" ]; then
  PARTS="$PARTS | $MODEL"
fi

if [ -n "$CONTEXT" ]; then
  PARTS="$PARTS | ${CONTEXT}%"
fi

# Session cost
if [ -n "$COST" ]; then
  PARTS="$PARTS | \$${COST}"
fi

# Worktree indicator (for parallel builds)
if [ -n "$WORKTREE" ]; then
  PARTS="$PARTS | wt:${WORKTREE}"
fi

# Mothership status with agent name
if [ -n "$AGENT" ]; then
  PARTS="$PARTS | mothership: ${AGENT} ${MOTHERSHIP_PHASE}"
else
  PARTS="$PARTS | mothership: ${MOTHERSHIP_PHASE}"
fi

printf '%b' "${GOLD}${PARTS}${RESET}"
