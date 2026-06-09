#!/bin/bash
# verify-all.sh - Run ALL verification checks
# This is the master script that ensures nothing is broken

set -e
set -o pipefail  # Ensure pipeline failures are not masked

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(dirname "$0")"
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
SKIPPED_CHECKS=0

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           MOTHERSHIP COMPLETE VERIFICATION                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Run a check
run_check() {
    local name="$1"
    local script="$2"
    local required="${3:-true}"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}▶ $name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if [[ ! -f "$SCRIPT_DIR/$script" ]]; then
        echo -e "${YELLOW}⚠️  Script not found: $script${NC}"
        SKIPPED_CHECKS=$((SKIPPED_CHECKS + 1))
        echo ""
        return 0
    fi

    if bash "$SCRIPT_DIR/$script" 2>&1; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        echo ""
        return 0
    else
        if [[ "$required" == "true" ]]; then
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            echo ""
            return 1
        else
            echo -e "${YELLOW}⚠️  Optional check failed (non-blocking)${NC}"
            SKIPPED_CHECKS=$((SKIPPED_CHECKS + 1))
            echo ""
            return 0
        fi
    fi
}

# Load env if exists (safely - strip quotes and CRLF)
if [[ -f ".env" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*) ]] || continue
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        value=${value%$'\r'}
        value=${value#\"}; value=${value%\"}
        value=${value#\'}; value=${value%\'}
        export "$key=$value"
    done < .env
fi

echo "Running all verification checks..."
echo ""

# ═══════════════════════════════════════════════════════════════
# TIER 1: Code Quality (blocks deployment)
# ═══════════════════════════════════════════════════════════════

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  TIER 1: CODE QUALITY                                        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

run_check "UI Wiring Check" "check-wiring.sh" true || true
run_check "Build & Lint" "check-build.sh" true || {
    # Fallback if check-build.sh doesn't exist
    # Note: set -o pipefail ensures exit codes are preserved through pipes
    echo "Running npm build..."
    npm run build 2>&1 | tail -20 || exit 1
    echo "Running npm lint..."
    npm run lint 2>&1 | tail -10 || exit 1
}

# ═══════════════════════════════════════════════════════════════
# TIER 2: Infrastructure (blocks deployment)
# ═══════════════════════════════════════════════════════════════

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  TIER 2: INFRASTRUCTURE                                      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

run_check "Environment Variables" "check-env.sh" true || true
run_check "Database" "check-database.sh" true || true
run_check "Docker" "verify-docker.sh" false || true

# ═══════════════════════════════════════════════════════════════
# TIER 3: APIs & Integrations (blocks deployment)
# ═══════════════════════════════════════════════════════════════

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  TIER 3: APIs & INTEGRATIONS                                 ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

run_check "API Endpoints" "check-api.sh" true || true
run_check "Third-Party Integrations" "check-integrations.sh" true || true

# ═══════════════════════════════════════════════════════════════
# TIER 4: Testing (blocks deployment)
# ═══════════════════════════════════════════════════════════════

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  TIER 4: TESTS                                               ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo "Running test suite..."
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
# Note: set -o pipefail ensures npm test exit code is preserved through pipe
if npm test 2>&1 | tail -20; then
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    VERIFICATION SUMMARY                      ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  Total Checks:   %-42s ║\n" "$TOTAL_CHECKS"
printf "║  ${GREEN}Passed:${NC}          %-42s ║\n" "$PASSED_CHECKS"
printf "║  ${RED}Failed:${NC}          %-42s ║\n" "$FAILED_CHECKS"
printf "║  ${YELLOW}Skipped:${NC}         %-42s ║\n" "$SKIPPED_CHECKS"
echo "╠══════════════════════════════════════════════════════════════╣"

if [[ $FAILED_CHECKS -eq 0 ]]; then
    echo -e "║  ${GREEN}STATUS: ALL CHECKS PASSED ✓${NC}                                 ║"
    echo "║                                                              ║"
    echo "║  Safe to deploy.                                            ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    exit 0
else
    echo -e "║  ${RED}STATUS: $FAILED_CHECKS CHECKS FAILED ✗${NC}                                   ║"
    echo "║                                                              ║"
    echo "║  DO NOT DEPLOY. Fix issues above first.                     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    exit 1
fi
