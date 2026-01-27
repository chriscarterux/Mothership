#!/bin/bash
# Mothership Core Loop - Iterative build/test/plan automation
# Works with any AI CLI tool (claude, cursor, aider, openai, etc.)

set -e

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Error handling
error() {
    echo -e "${RED}🛸 Error: $1${NC}" >&2
    exit 1
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

info() {
    echo -e "${CYAN}🛸 $1${NC}"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

trap 'echo -e "\n\n${YELLOW}🛸 Interrupted. Progress saved to .mothership/progress.md${NC}"; exit 130' INT

# Parse arguments
MODE="${1:-build}"
MAX_ITERATIONS="${2:-10}"
PLAN_CONTEXT="$2"

# Token counting (approximate: words × 1.3)
# Actual tokens may vary ~20% based on content structure
# Does not include docs/code context loaded by AI tool
count_tokens() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local words=$(wc -w < "$file" | tr -d ' ')
        echo $(( words * 13 / 10 ))
    else
        echo 0
    fi
}

# Validate mode
case "$MODE" in
    # Development modes
    build|test|plan|review) ;;

    # Verification modes
    quick-check|verify|test-matrix|test-contracts|test-rollback) ;;

    # Infrastructure modes
    verify-env|health-check|inventory) ;;

    # Utility modes
    status|onboard) ;;

    benchmark)
        echo ""
        echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
        echo -e "${BLUE}  🛸 Mothership Core Benchmark${NC}"
        echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
        echo ""

        TOTAL=0

        if [[ -f ".mothership/mothership.md" ]]; then
            TOKENS=$(count_tokens ".mothership/mothership.md")
            TOTAL=$((TOTAL + TOKENS))
            printf "  %-30s %6d tokens\n" ".mothership/mothership.md" "$TOKENS"
        fi

        if [[ -f ".mothership/checkpoint.md" ]]; then
            TOKENS=$(count_tokens ".mothership/checkpoint.md")
            TOTAL=$((TOTAL + TOKENS))
            printf "  %-30s %6d tokens\n" ".mothership/checkpoint.md" "$TOKENS"
        fi

        if [[ -f ".mothership/codebase.md" ]]; then
            TOKENS=$(count_tokens ".mothership/codebase.md")
            TOTAL=$((TOTAL + TOKENS))
            printf "  %-30s %6d tokens\n" ".mothership/codebase.md" "$TOKENS"
        fi

        echo ""
        echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"
        printf "  %-30s ${GREEN}%6d tokens${NC}\n" "TOTAL PER RUN" "$TOTAL"
        echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"
        echo ""

        # Cost calculation (Claude Sonnet: $3/1M input tokens)
        COST=$(echo "scale=4; $TOTAL * 3 / 1000000" | bc 2>/dev/null || echo "0.004")
        echo -e "  Estimated cost/run: ${CYAN}~\$${COST}${NC} (approximate, Claude Sonnet)"
        echo ""
        exit 0
        ;;

    doctor)
        echo ""
        echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
        echo -e "${BLUE}  🛸 Mothership Core Doctor${NC}"
        echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
        echo ""

        ISSUES=0

        # Check .mothership directory
        if [[ -d ".mothership" ]]; then
            success ".mothership/ directory exists"
        else
            echo -e "${RED}✗ No .mothership/ directory${NC}"
            ISSUES=$((ISSUES + 1))
        fi

        # Check mothership.md
        if [[ -f ".mothership/mothership.md" ]]; then
            TOKENS=$(count_tokens ".mothership/mothership.md")
            success ".mothership/mothership.md exists ($TOKENS tokens)"
        else
            echo -e "${RED}✗ No .mothership/mothership.md${NC}"
            ISSUES=$((ISSUES + 1))
        fi

        # Check AI tool
        if command -v claude &> /dev/null; then
            success "AI tool detected: claude"
        elif command -v gemini &> /dev/null; then
            success "AI tool detected: gemini"
        elif command -v codex &> /dev/null; then
            success "AI tool detected: codex"
        elif command -v opencode &> /dev/null; then
            success "AI tool detected: opencode"
        else
            echo -e "${RED}✗ No AI CLI tool found (claude, gemini, codex, opencode)${NC}"
            ISSUES=$((ISSUES + 1))
        fi

        # Check git
        if git rev-parse --git-dir > /dev/null 2>&1; then
            success "Git repository initialized"
        else
            echo -e "${RED}✗ Not a git repository${NC}"
            ISSUES=$((ISSUES + 1))
        fi

        # Check docs
        if [[ -d "docs" ]]; then
            DOC_COUNT=$(find docs -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
            success "docs/ directory exists ($DOC_COUNT files)"
        else
            warn "No docs/ directory - create docs to enable planning"
        fi

        # Check codebase.md
        if [[ -f ".mothership/codebase.md" ]]; then
            success ".mothership/codebase.md exists"
        else
            warn "No codebase.md - run 'onboard' mode to create"
        fi

        # Check config
        if [[ -f ".mothership/config.json" ]]; then
            success ".mothership/config.json exists"
        else
            warn "No config.json - using defaults"
        fi

        echo ""
        if [[ $ISSUES -eq 0 ]]; then
            echo -e "${GREEN}Ready to launch! 🛸${NC}"
        else
            echo -e "${RED}$ISSUES issue(s) found. Fix before running.${NC}"
        fi
        echo ""
        exit 0
        ;;

    trace)
        echo ""
        echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
        echo -e "${BLUE}  🛸 Mothership Core Trace${NC}"
        echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
        echo ""

        TRACE_MODE="${2:-build}"
        echo -e "  Tracing mode: ${CYAN}$TRACE_MODE${NC}"
        echo ""
        echo "  Files loaded per iteration:"
        echo ""

        TOTAL=0

        # Always load mothership.md
        if [[ -f ".mothership/mothership.md" ]]; then
            TOKENS=$(count_tokens ".mothership/mothership.md")
            TOTAL=$((TOTAL + TOKENS))
            printf "    %-28s %6d tokens\n" ".mothership/mothership.md" "$TOKENS"
        fi

        # Always load checkpoint if exists
        if [[ -f ".mothership/checkpoint.md" ]]; then
            TOKENS=$(count_tokens ".mothership/checkpoint.md")
            TOTAL=$((TOTAL + TOKENS))
            printf "    %-28s %6d tokens\n" ".mothership/checkpoint.md" "$TOKENS"
        fi

        # Load codebase.md for build/test modes
        if [[ "$TRACE_MODE" == "build" || "$TRACE_MODE" == "test" ]]; then
            if [[ -f ".mothership/codebase.md" ]]; then
                TOKENS=$(count_tokens ".mothership/codebase.md")
                TOTAL=$((TOTAL + TOKENS))
                printf "    %-28s %6d tokens\n" ".mothership/codebase.md" "$TOKENS"
            fi
        fi

        echo ""
        echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"
        printf "    %-28s ${GREEN}%6d tokens${NC}\n" "TOTAL" "$TOTAL"
        echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"
        echo ""
        exit 0
        ;;

    -h|--help|help)
        echo "Usage: ./mothership.sh [mode] [max_iterations]"
        echo ""
        echo "Development Modes:"
        echo "  plan [feature]  Create stories from feature description"
        echo "  build [n]       Build features (default: 10 iterations)"
        echo "  test [n]        Run and fix tests (default: 10 iterations)"
        echo "  review          Review code quality"
        echo ""
        echo "Verification Modes:"
        echo "  quick-check     Fast sanity check (unwired UI, crashed containers)"
        echo "  verify          Runtime verification that code actually works"
        echo "  test-matrix     Comprehensive testing (Unit, Integration, API, E2E, Security, A11y)"
        echo "  test-contracts  API contract testing between frontend/backend"
        echo "  test-rollback   Verify rollback procedures work"
        echo ""
        echo "Infrastructure Modes:"
        echo "  verify-env      Check env vars, services, certificates"
        echo "  health-check    Verify all integrations (DB, Stripe, Email, AI)"
        echo "  inventory       Discover and catalog all APIs, components"
        echo ""
        echo "Utility Modes:"
        echo "  status          Report current project state"
        echo "  onboard         Scan project and create codebase.md"
        echo ""
        echo "Tooling:"
        echo "  benchmark       Show token counts for your setup"
        echo "  doctor          Diagnose setup issues"
        echo "  trace [mode]    Show what gets loaded for a mode"
        echo ""
        echo "Examples:"
        echo "  ./mothership.sh plan \"user authentication\""
        echo "  ./mothership.sh build 20"
        echo "  ./mothership.sh quick-check"
        echo "  ./mothership.sh verify-env"
        echo "  ./mothership.sh benchmark"
        echo ""
        echo "Workflow:"
        echo "  onboard → inventory → plan → build → quick-check → verify →"
        echo "  test-matrix → test-contracts → test → review →"
        echo "  verify-env → test-rollback → deploy → health-check"
        echo ""
        echo "Environment:"
        echo "  AI_TOOL    Override AI CLI detection (default: auto-detect)"
        echo "             Example: AI_TOOL=claude ./mothership.sh build"
        exit 0
        ;;
    *)
        error "Unknown mode: '$MODE'

Development:    plan, build, test, review
Verification:   quick-check, verify, test-matrix, test-contracts, test-rollback
Infrastructure: verify-env, health-check, inventory
Utility:        status, onboard

Run './mothership.sh --help' for full usage"
        ;;
esac

# Check for .mothership directory
if [[ ! -d ".mothership" ]]; then
    error "No .mothership/ directory found

To set up Mothership Core, run:
  curl -fsSL https://raw.githubusercontent.com/chriscarterux/Mothership---Core/main/install.sh | bash

Or manually create .mothership/ with mothership.md"
fi

# Check for mothership.md
if [[ ! -f ".mothership/mothership.md" ]]; then
    error "No .mothership/mothership.md found

Run the installer to set up:
  curl -fsSL https://raw.githubusercontent.com/chriscarterux/Mothership---Core/main/install.sh | bash"
fi

# Detect AI tool (set AI_TOOL env var or auto-detect)
# Primary: claude, gemini, codex, opencode
if [[ -n "$AI_TOOL" ]]; then
    AI_CMD="$AI_TOOL"
    if ! command -v "$AI_CMD" &> /dev/null; then
        error "AI tool '$AI_CMD' not found in PATH

Either:
  1. Install $AI_CMD
  2. Set AI_TOOL to a valid CLI tool
  3. Add $AI_CMD to your PATH"
    fi
elif command -v claude &> /dev/null; then
    AI_CMD="claude"
elif command -v gemini &> /dev/null; then
    AI_CMD="gemini"
elif command -v codex &> /dev/null; then
    AI_CMD="codex"
elif command -v opencode &> /dev/null; then
    AI_CMD="opencode"
else
    error "No AI CLI tool found

Supported tools:
  • claude   - Anthropic Claude Code
  • gemini   - Google Gemini CLI
  • codex    - OpenAI Codex CLI
  • opencode - OpenCode CLI

Or set AI_TOOL environment variable:
  AI_TOOL=my-ai-cli ./mothership.sh build"
fi

# Detect if specialized agents are installed
if [[ -d ".mothership/agents" ]]; then
    VERSION="agents"
else
    VERSION="core"
fi

# Archive previous run if exists
ARCHIVE_DIR=".mothership/archive"
if [ -f ".mothership/checkpoint.md" ]; then
    CURRENT_PROJECT=$(grep "^project:" .mothership/checkpoint.md 2>/dev/null | cut -d' ' -f2- || echo "")
    if [ -n "$CURRENT_PROJECT" ] && [ "$CURRENT_PROJECT" != "null" ]; then
        DATE=$(date +%Y-%m-%d)
        ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$(echo $CURRENT_PROJECT | tr ' ' '-' | tr '[:upper:]' '[:lower:]')"
        
        if [ ! -d "$ARCHIVE_FOLDER" ]; then
            info "Archiving previous run: $CURRENT_PROJECT"
            mkdir -p "$ARCHIVE_FOLDER"
            [ -f ".mothership/checkpoint.md" ] && cp .mothership/checkpoint.md "$ARCHIVE_FOLDER/"
            [ -f ".mothership/stories.json" ] && cp .mothership/stories.json "$ARCHIVE_FOLDER/"
            [ -f ".mothership/progress.md" ] && cp .mothership/progress.md "$ARCHIVE_FOLDER/"
        fi
    fi
fi

# Set completion signals based on mode
# BUILD-COMPLETE = no more stories to build (stop looping)
# BUILT:* = one story done (continue to next iteration)
case "$MODE" in
    # Development modes
    build)   COMPLETE_SIGNALS="BUILD-COMPLETE" ;;
    test)    COMPLETE_SIGNALS="TEST-COMPLETE" ;;
    plan)    COMPLETE_SIGNALS="PLANNED:[0-9]+|PLANNED"; MAX_ITERATIONS=1 ;;
    review)  COMPLETE_SIGNALS="APPROVED|NEEDS-WORK"; MAX_ITERATIONS=1 ;;

    # Verification modes (one-shot, stop on pass OR fail)
    quick-check)    COMPLETE_SIGNALS="QUICK-CHECK:pass|QUICK-CHECK:fail"; MAX_ITERATIONS=1 ;;
    verify)         COMPLETE_SIGNALS="VERIFIED|UNWIRED"; MAX_ITERATIONS=1 ;;
    test-matrix)    COMPLETE_SIGNALS="MATRIX-PASS|MATRIX-FAIL"; MAX_ITERATIONS=1 ;;
    test-contracts) COMPLETE_SIGNALS="CONTRACTS-VALID|CONTRACTS-VIOLATED|BREAKING-CHANGES"; MAX_ITERATIONS=1 ;;
    test-rollback)  COMPLETE_SIGNALS="ROLLBACK-VERIFIED|ROLLBACK-FAILED"; MAX_ITERATIONS=1 ;;

    # Infrastructure modes (one-shot)
    verify-env)   COMPLETE_SIGNALS="ENV-VERIFIED|ENV-FAILED"; MAX_ITERATIONS=1 ;;
    health-check) COMPLETE_SIGNALS="HEALTHY|UNHEALTHY"; MAX_ITERATIONS=1 ;;
    inventory)    COMPLETE_SIGNALS="INVENTORY-COMPLETE"; MAX_ITERATIONS=1 ;;

    # Utility modes
    status)  COMPLETE_SIGNALS="STATUS-COMPLETE"; MAX_ITERATIONS=1 ;;
    onboard) COMPLETE_SIGNALS="ONBOARD-COMPLETE"; MAX_ITERATIONS=1 ;;
esac

# Header
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  🛸 Mothership Core Loop${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Mode:       ${CYAN}$MODE${NC}"
echo -e "  Iterations: ${CYAN}$MAX_ITERATIONS${NC}"
echo -e "  Version:    ${CYAN}$VERSION${NC}"
echo -e "  AI Tool:    ${CYAN}$AI_CMD${NC}"
echo ""

# Initialize progress log
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting $MODE mode" >> .mothership/progress.md

for ((i=1; i<=MAX_ITERATIONS; i++)); do
    echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"
    echo -e " Iteration ${CYAN}$i${NC} of ${CYAN}$MAX_ITERATIONS${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"
    
    # Build the prompt
    if [[ "$MODE" == "plan" && -n "$PLAN_CONTEXT" ]]; then
        PROMPT="Read .mothership/mothership.md and run: plan $PLAN_CONTEXT"
    else
        PROMPT="Read .mothership/mothership.md and run: $MODE"
    fi
    
    # Run AI tool and capture output
    OUTPUT=$(echo "$PROMPT" | $AI_CMD 2>&1) || {
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 130 ]; then
            exit 130  # User interrupted
        fi
        warn "AI tool exited with code $EXIT_CODE"
        # If AI tool failed AND output is empty, that's an error
        if [[ -z "$OUTPUT" ]]; then
            error "AI tool failed with no output (exit code: $EXIT_CODE)"
        fi
    }
    echo "$OUTPUT"

    # Log to progress.md
    echo "" >> .mothership/progress.md
    echo "### Iteration $i - $(date '+%H:%M:%S')" >> .mothership/progress.md
    echo '```' >> .mothership/progress.md
    echo "$OUTPUT" | tail -50 >> .mothership/progress.md
    echo '```' >> .mothership/progress.md
    
    # Check for completion signals (must be in proper <agent>SIGNAL</agent> format)
    # BUILD-COMPLETE means no more stories - stop the loop
    # BUILT:ID means one story done - continue to next iteration
    # Agent names: mothership (unified), vector (build), cortex (test), cipher (plan),
    #              sentinel (review/env), atomic (verify), sanity (quick-check),
    #              nexus (test-matrix/contracts), phoenix (rollback), scanner (inventory),
    #              pulse (health-check)
    if echo "$OUTPUT" | grep -qE "<(mothership|vector|cortex|cipher|sentinel|atomic|sanity|nexus|phoenix|scanner|pulse)>($COMPLETE_SIGNALS)</"; then
        echo ""
        success "Mothership Core complete! Finished at iteration $i."
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Completed at iteration $i" >> .mothership/progress.md
        exit 0
    fi
    
    # Check for blocked signal (must use proper tag format like other signals)
    if echo "$OUTPUT" | grep -qE "<(mothership|vector|cortex|cipher|sentinel|atomic|sanity|nexus|phoenix|scanner|pulse)>(BLOCKED|X:[^<]+)</(mothership|vector|cortex|cipher|sentinel|atomic|sanity|nexus|phoenix|scanner|pulse)>"; then
        echo ""
        warn "Agent reported BLOCKED. Check output above for details."
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Blocked at iteration $i" >> .mothership/progress.md
        exit 1
    fi
    
    echo ""
    info "Iteration $i complete. Continuing..."
    echo ""
    sleep 1
done

echo ""
warn "Reached max iterations ($MAX_ITERATIONS)"
echo ""
echo "Next steps:"
echo "  1. Check .mothership/progress.md for status"
echo "  2. Run again with more iterations: ./mothership.sh $MODE $((MAX_ITERATIONS * 2))"
echo "  3. Check .mothership/checkpoint.md for current state"
echo ""
echo "$(date '+%Y-%m-%d %H:%M:%S') - Reached max iterations" >> .mothership/progress.md
exit 1
