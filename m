#!/bin/bash
# Mothership - Minimal Entry Point
# Usage: ./m [mode] [story-type]

set -e

MODE="${1:-status}"
TYPE="${2:-}"

# Colors
R='\033[0;31m' G='\033[0;32m' Y='\033[0;33m' B='\033[0;34m' N='\033[0m'

# Auto-detect AI tool
detect_ai() {
    for cmd in claude gemini codex opencode; do
        command -v "$cmd" &>/dev/null && echo "$cmd" && return
    done
    echo "none"
}

AI=$(detect_ai)

# Quick help
if [[ "$MODE" == "-h" || "$MODE" == "help" ]]; then
    echo -e "${B}Mothership${N} - Autonomous Dev Loop"
    echo ""
    echo "Usage: ./m [mode] [type]"
    echo ""
    echo "Modes:"
    echo "  plan     Create atomic stories from requirements"
    echo "  build    Implement one story with verification"
    echo "  test     Run verification suite"
    echo "  review   Check for gaps and issues"
    echo "  status   Show current progress"
    echo "  verify   Run all checks"
    echo ""
    echo "Types (for build): ui, api, database, integration, fullstack"
    echo ""
    echo "Examples:"
    echo "  ./m plan              # Start planning"
    echo "  ./m build ui          # Build a UI story"
    echo "  ./m verify            # Run all checks"
    exit 0
fi

# Run verification based on type
verify() {
    local t="${1:-all}"
    echo -e "${B}Verifying: $t${N}"

    case "$t" in
        ui)         ./scripts/check-wiring.sh src/ 2>/dev/null || true ;;
        api)        ./scripts/check-api.sh 2>/dev/null || true ;;
        database)   ./scripts/check-database.sh 2>/dev/null || true ;;
        integration) ./scripts/check-integrations.sh 2>/dev/null || true ;;
        fullstack|all) ./scripts/verify-all.sh 2>/dev/null || true ;;
    esac
}

# Main dispatch
case "$MODE" in
    plan|build|test|review|status)
        if [[ "$AI" == "none" ]]; then
            echo -e "${R}No AI tool found. Install claude, gemini, codex, or opencode.${N}"
            exit 1
        fi

        echo -e "${G}▶ Running: $MODE${N}"
        [[ -n "$TYPE" ]] && echo -e "${Y}  Type: $TYPE${N}"

        # Build prompt
        PROMPT="Execute mothership mode: $MODE"
        [[ -n "$TYPE" ]] && PROMPT="$PROMPT for story type: $TYPE"

        # Run AI with compact prompt
        case "$AI" in
            claude) claude --print -p "$PROMPT" ;;
            gemini) gemini "$PROMPT" ;;
            codex)  codex "$PROMPT" ;;
            opencode) opencode "$PROMPT" ;;
        esac
        ;;

    verify|v)
        verify "$TYPE"
        ;;

    quick|q)
        echo -e "${B}Quick Check${N}"
        # Fast sanity checks
        [[ -f "package.json" ]] && npm run build --if-present 2>/dev/null && echo -e "${G}✓ Build OK${N}" || true
        [[ -f "package.json" ]] && npm test --if-present 2>/dev/null && echo -e "${G}✓ Tests OK${N}" || true
        git status --short
        ;;

    *)
        echo -e "${R}Unknown mode: $MODE${N}"
        echo "Run ./m help for usage"
        exit 1
        ;;
esac
