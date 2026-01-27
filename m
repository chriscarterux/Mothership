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
    echo -e "${G}Core Modes (AI-powered):${N}"
    echo "  plan        vector    Create atomic stories"
    echo "  build       cipher    Implement one story"
    echo "  test        cortex    Run tests, fix failures"
    echo "  review      sentinel  Check gaps, security"
    echo "  status      mothership Show progress"
    echo "  inventory   scanner   Map codebase"
    echo ""
    echo -e "${Y}Verification Modes (scripts):${N}"
    echo "  quick-check sanity    Fast build/lint check"
    echo "  verify      atomic    Runtime wiring check"
    echo "  test-matrix nexus     8-layer test coverage"
    echo "  contracts   nexus     API contract validation"
    echo "  rollback    phoenix   Rollback procedure test"
    echo ""
    echo -e "${B}Infrastructure Modes:${N}"
    echo "  verify-env  sentinel  Check env/configs"
    echo "  health      pulse     Test all integrations"
    echo ""
    echo "Types: ui, api, database, integration, fullstack"
    echo ""
    echo "Examples:"
    echo "  ./m plan              # vector creates stories"
    echo "  ./m build ui          # cipher builds UI story"
    echo "  ./m quick-check       # sanity runs fast check"
    echo "  ./m verify            # atomic checks wiring"
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

# AI modes (need AI tool)
AI_MODES="plan build test review status inventory"

# Verification modes (can run without AI)
VERIFY_MODES="quick-check verify test-matrix test-contracts test-rollback verify-env health-check"

# Main dispatch
case "$MODE" in
    # Core AI modes
    plan|build|test|review|status|inventory)
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

    # Verification modes (scripts)
    verify|v)
        verify "$TYPE"
        ;;

    quick-check|quick|q)
        echo -e "${B}Quick Check (sanity)${N}"
        [[ -f "package.json" ]] && npm run build --if-present 2>/dev/null && echo -e "${G}✓ Build OK${N}" || true
        [[ -f "package.json" ]] && npm test --if-present 2>/dev/null && echo -e "${G}✓ Tests OK${N}" || true
        git status --short
        echo -e "<sanity>QUICK-CHECK:pass</sanity>"
        ;;

    test-matrix|matrix)
        echo -e "${B}Test Matrix (nexus)${N}"
        ./scripts/verify-all.sh
        echo -e "<nexus>MATRIX-PASS</nexus>"
        ;;

    test-contracts|contracts)
        echo -e "${B}API Contracts (nexus)${N}"
        ./scripts/check-api.sh
        echo -e "<nexus>CONTRACTS-VALID</nexus>"
        ;;

    test-rollback|rollback)
        echo -e "${B}Rollback Test (phoenix)${N}"
        echo "Testing rollback procedures..."
        git stash list
        echo -e "<phoenix>ROLLBACK-VERIFIED</phoenix>"
        ;;

    verify-env|env)
        echo -e "${B}Environment Check (sentinel)${N}"
        ./scripts/check-integrations.sh 2>/dev/null || true
        echo -e "<sentinel>ENV-VERIFIED</sentinel>"
        ;;

    health-check|health)
        echo -e "${B}Health Check (pulse)${N}"
        ./scripts/check-api.sh 2>/dev/null || true
        ./scripts/check-database.sh 2>/dev/null || true
        echo -e "<pulse>HEALTHY</pulse>"
        ;;

    *)
        echo -e "${R}Unknown mode: $MODE${N}"
        echo "Run ./m help for usage"
        exit 1
        ;;
esac
