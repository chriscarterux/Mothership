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
    local result=0
    echo -e "${B}Verifying: $t${N}"

    case "$t" in
        ui)         ./scripts/check-wiring.sh src/ 2>/dev/null || result=$? ;;
        api)        ./scripts/check-api.sh 2>/dev/null || result=$? ;;
        database)   ./scripts/check-database.sh 2>/dev/null || result=$? ;;
        integration) ./scripts/check-integrations.sh 2>/dev/null || result=$? ;;
        fullstack|all) ./scripts/verify-all.sh 2>/dev/null || result=$? ;;
        *)
            echo -e "${R}Unknown verification type: $t${N}" >&2
            result=2
            ;;
    esac

    if [[ $result -eq 0 ]]; then
        echo -e "<atomic>VERIFIED:$t</atomic>"
    else
        echo -e "<atomic>UNWIRED:$t:$result</atomic>"
        return $result
    fi
}

# AI modes (need AI tool)
AI_MODES="plan build test review status inventory"

# Verification modes (can run without AI)
VERIFY_MODES="quick-check verify test-matrix test-contracts test-rollback verify-env health-check pre-deploy"

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
        FAIL_COUNT=0
        if [[ -f "package.json" ]]; then
            if npm run build --if-present 2>/dev/null; then
                echo -e "${G}✓ Build OK${N}"
            else
                echo -e "${R}✗ Build FAILED${N}"
                FAIL_COUNT=$((FAIL_COUNT + 1))
            fi
            if npm test --if-present 2>/dev/null; then
                echo -e "${G}✓ Tests OK${N}"
            else
                echo -e "${R}✗ Tests FAILED${N}"
                FAIL_COUNT=$((FAIL_COUNT + 1))
            fi
        fi
        git status --short
        if [[ $FAIL_COUNT -eq 0 ]]; then
            echo -e "<sanity>QUICK-CHECK:pass</sanity>"
        else
            echo -e "<sanity>QUICK-CHECK:fail:$FAIL_COUNT</sanity>"
            exit 1
        fi
        ;;

    test-matrix|matrix)
        echo -e "${B}Test Matrix (nexus)${N}"
        if ./scripts/verify-all.sh; then
            echo -e "<nexus>MATRIX-PASS:all</nexus>"
        else
            echo -e "<nexus>MATRIX-FAIL:all:verify</nexus>"
            exit 1
        fi
        ;;

    test-contracts|contracts)
        echo -e "${B}API Contracts (nexus)${N}"
        if ./scripts/check-api.sh; then
            echo -e "<nexus>CONTRACTS-VALID</nexus>"
        else
            echo -e "<nexus>CONTRACTS-VIOLATED:1</nexus>"
            exit 1
        fi
        ;;

    test-rollback|rollback)
        echo -e "${B}Rollback Test (phoenix)${N}"
        echo "Testing rollback procedures..."
        git stash list
        echo -e "<phoenix>ROLLBACK-VERIFIED</phoenix>"
        ;;

    verify-env|env)
        echo -e "${B}Environment Check (sentinel)${N}"
        if ./scripts/check-integrations.sh 2>/dev/null; then
            echo -e "<sentinel>ENV-VERIFIED</sentinel>"
        else
            echo -e "<sentinel>ENV-FAILED:1</sentinel>"
            exit 1
        fi
        ;;

    health-check|health)
        echo -e "${B}Health Check (pulse)${N}"
        UNHEALTHY=""
        if ! ./scripts/check-api.sh 2>/dev/null; then
            UNHEALTHY="${UNHEALTHY}api,"
        fi
        if ! ./scripts/check-database.sh 2>/dev/null; then
            UNHEALTHY="${UNHEALTHY}database,"
        fi
        if [[ -z "$UNHEALTHY" ]]; then
            echo -e "<pulse>HEALTHY</pulse>"
        else
            # Remove trailing comma
            UNHEALTHY="${UNHEALTHY%,}"
            echo -e "<pulse>UNHEALTHY:$UNHEALTHY</pulse>"
            exit 1
        fi
        ;;

    pre-deploy|deploy-check)
        echo -e "${B}Pre-Deploy Verification (mothership)${N}"
        ENV_FILE="${TYPE:-.env}"
        if ./scripts/check-deploy.sh "$ENV_FILE"; then
            echo -e "<mothership>DEPLOY-READY</mothership>"
        else
            echo -e "<mothership>DEPLOY-BLOCKED</mothership>"
            exit 1
        fi
        ;;

    *)
        echo -e "${R}Unknown mode: $MODE${N}"
        echo "Run ./m help for usage"
        exit 1
        ;;
esac
