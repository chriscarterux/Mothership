#!/bin/bash
# check-deploy.sh - Pre-deployment verification
# Catches common deployment issues BEFORE you deploy
# Exit code 1 = issues found, 0 = safe to deploy

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ISSUES=0
WARNINGS=0

echo "╔════════════════════════════════════════════╗"
echo "║       PRE-DEPLOYMENT VERIFICATION          ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Load env vars (safely)
ENV_FILE="${1:-.env}"
if [[ -f "$ENV_FILE" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]] && export "$line"
    done < "$ENV_FILE"
    echo -e "${GREEN}✓ Loaded $ENV_FILE${NC}"
else
    echo -e "${RED}❌ Environment file not found: $ENV_FILE${NC}"
    ISSUES=$((ISSUES + 1))
fi

echo ""
echo -e "${BLUE}━━━ 1. Environment Variables ━━━${NC}"

# Check required vars exist
check_var() {
    local var_name="$1"
    local required="${2:-true}"
    local redact="${3:-false}"

    if [[ -n "${!var_name}" ]]; then
        if [[ "$redact" == "true" ]]; then
            echo -e "${GREEN}✓ $var_name${NC} = [REDACTED]"
        else
            echo -e "${GREEN}✓ $var_name${NC}"
        fi
        return 0
    else
        if [[ "$required" == "true" ]]; then
            echo -e "${RED}❌ $var_name not set (required)${NC}"
            ISSUES=$((ISSUES + 1))
        else
            echo -e "${YELLOW}⚠️  $var_name not set (optional)${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
        return 1
    fi
}

# Essential vars
check_var "DATABASE_URL" true true
check_var "NEXTAUTH_SECRET" true true
check_var "NEXTAUTH_URL" true

# Payment (if Stripe files exist) - use compgen/find for robustness
if compgen -G "app/api/*stripe*" > /dev/null 2>&1 || \
   compgen -G "pages/api/*stripe*" > /dev/null 2>&1 || \
   find src -name "*stripe*" -print -quit 2>/dev/null | grep -q .; then
    check_var "STRIPE_SECRET_KEY" true true
    check_var "STRIPE_WEBHOOK_SECRET" true true
    check_var "NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY" true
fi

# Email (at least one)
if [[ -z "$RESEND_API_KEY" && -z "$SENDGRID_API_KEY" && -z "$SMTP_HOST" ]]; then
    echo -e "${YELLOW}⚠️  No email service configured${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    check_var "RESEND_API_KEY" false true || \
    check_var "SENDGRID_API_KEY" false true || \
    check_var "SMTP_HOST" false
fi

# AI (if local AI configured)
if [[ "$USE_LOCAL_AI" == "true" ]]; then
    check_var "OLLAMA_URL" true
    check_var "OLLAMA_MODEL" true
fi

echo ""
echo -e "${BLUE}━━━ 2. Build Freshness ━━━${NC}"

# Check if build exists and is recent
if [[ -d ".next" ]]; then
    BUILD_TIME=$(stat -c %Y .next/BUILD_ID 2>/dev/null || stat -f %m .next/BUILD_ID 2>/dev/null || echo 0)
    # Detect stat syntax (GNU vs BSD) and get most recent source file time
    if stat -c %Y . >/dev/null 2>&1; then
        # GNU stat
        SOURCE_TIME=$(find . \( -name "*.ts" -o -name "*.tsx" \) -type f | head -100 | xargs stat -c %Y 2>/dev/null | sort -rn | head -1)
    else
        # BSD stat (macOS)
        SOURCE_TIME=$(find . \( -name "*.ts" -o -name "*.tsx" \) -type f | head -100 | xargs stat -f %m 2>/dev/null | sort -rn | head -1)
    fi
    SOURCE_TIME=${SOURCE_TIME:-0}

    if [[ $BUILD_TIME -lt $SOURCE_TIME ]]; then
        echo -e "${RED}❌ Build is stale (source files modified after build)${NC}"
        echo "   Run: npm run build"
        ISSUES=$((ISSUES + 1))
    else
        echo -e "${GREEN}✓ Build is up to date${NC}"
    fi
else
    echo -e "${RED}❌ No build found (.next directory missing)${NC}"
    echo "   Run: npm run build"
    ISSUES=$((ISSUES + 1))
fi

# Check for uncommitted changes
if git status --porcelain | grep -q '^[AMDRC]'; then
    echo -e "${YELLOW}⚠️  Uncommitted changes in staging area${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo -e "${BLUE}━━━ 3. Docker Configuration ━━━${NC}"

if [[ -f "Dockerfile" ]]; then
    echo -e "${GREEN}✓ Dockerfile exists${NC}"

    # Check for multi-stage build (recommended for Next.js)
    if grep -q "FROM.*AS builder" Dockerfile; then
        echo -e "${GREEN}✓ Multi-stage build configured${NC}"
    else
        echo -e "${YELLOW}⚠️  Consider multi-stage build for smaller images${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Check for .dockerignore
    if [[ -f ".dockerignore" ]]; then
        echo -e "${GREEN}✓ .dockerignore exists${NC}"
    else
        echo -e "${YELLOW}⚠️  No .dockerignore (builds may be slow)${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Check for secrets in Dockerfile
    if grep -iE "(password|secret|key|token)=" Dockerfile | grep -v "ARG\|ENV.*\$"; then
        echo -e "${RED}❌ Potential secrets hardcoded in Dockerfile${NC}"
        ISSUES=$((ISSUES + 1))
    fi
fi

if [[ -f "docker-compose.yml" ]] || [[ -f "docker-compose.deploy.yml" ]]; then
    COMPOSE_FILE="${DOCKER_COMPOSE_FILE:-docker-compose.yml}"
    [[ -f "docker-compose.deploy.yml" ]] && COMPOSE_FILE="docker-compose.deploy.yml"

    echo -e "${GREEN}✓ Docker Compose file exists${NC}"

    # Check for volume mounts (data persistence)
    if grep -q "volumes:" "$COMPOSE_FILE"; then
        echo -e "${GREEN}✓ Volumes configured (data persistence)${NC}"
    else
        echo -e "${YELLOW}⚠️  No volumes - data won't persist across restarts${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Check for health checks
    if grep -q "healthcheck:" "$COMPOSE_FILE"; then
        echo -e "${GREEN}✓ Health checks configured${NC}"
    else
        echo -e "${YELLOW}⚠️  No health checks in compose file${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

echo ""
echo -e "${BLUE}━━━ 4. Service Reachability ━━━${NC}"

# Test database connection
if [[ -n "$DATABASE_URL" ]]; then
    echo -n "Testing database connection... "
    if psql "$DATABASE_URL" -c "SELECT 1" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Connected${NC}"

        # Check for tables (migrations run?)
        TABLE_COUNT=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'" 2>/dev/null | tr -d ' ')
        # Handle empty or non-numeric TABLE_COUNT
        if [[ -z "$TABLE_COUNT" || "$TABLE_COUNT" -eq 0 ]]; then
            echo -e "${RED}❌ Database has 0 tables - run migrations!${NC}"
            ISSUES=$((ISSUES + 1))
        else
            echo -e "${GREEN}✓ Database has $TABLE_COUNT tables${NC}"
        fi
    else
        echo -e "${RED}❌ Cannot connect to database${NC}"
        ISSUES=$((ISSUES + 1))
    fi
fi

# Test Ollama if configured
if [[ -n "$OLLAMA_URL" ]]; then
    echo -n "Testing Ollama connection... "
    if curl -s --max-time 5 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Ollama reachable${NC}"

        # Check binding for Docker access (use lsof for macOS portability)
        OLLAMA_PORT="${OLLAMA_URL##*:}"
        OLLAMA_PORT="${OLLAMA_PORT%%/*}"
        # Default to 11434 if no port found (Ollama default)
        [[ ! "$OLLAMA_PORT" =~ ^[0-9]+$ ]] && OLLAMA_PORT=11434
        if lsof -iTCP:"$OLLAMA_PORT" -sTCP:LISTEN 2>/dev/null | grep -q "127.0.0.1\|localhost"; then
            echo -e "${RED}❌ Ollama only on localhost - containers can't reach it${NC}"
            echo "   Set OLLAMA_HOST=0.0.0.0 in Ollama config"
            ISSUES=$((ISSUES + 1))
        elif lsof -iTCP:"$OLLAMA_PORT" -sTCP:LISTEN 2>/dev/null | grep -q "\*:"; then
            echo -e "${GREEN}✓ Ollama accessible from containers${NC}"
        fi
    else
        echo -e "${RED}❌ Ollama not reachable at $OLLAMA_URL${NC}"
        ISSUES=$((ISSUES + 1))
    fi
fi

echo ""
echo -e "${BLUE}━━━ 5. Security Checks ━━━${NC}"

# Check for exposed secrets in code
if grep -rn "sk_live_\|sk_test_\|password.*=.*['\"]" --include="*.ts" --include="*.tsx" --include="*.js" . 2>/dev/null | grep -v node_modules | grep -v ".env"; then
    echo -e "${RED}❌ Potential secrets in source code${NC}"
    ISSUES=$((ISSUES + 1))
else
    echo -e "${GREEN}✓ No hardcoded secrets found${NC}"
fi

# Check .env not in git
if git ls-files --error-unmatch .env 2>/dev/null; then
    echo -e "${RED}❌ .env is tracked by git!${NC}"
    ISSUES=$((ISSUES + 1))
else
    echo -e "${GREEN}✓ .env is not tracked by git${NC}"
fi

# Summary
echo ""
echo "════════════════════════════════════════════"
if [[ $ISSUES -gt 0 ]]; then
    echo -e "${RED}BLOCKED: $ISSUES issues must be fixed before deploy${NC}"
    [[ $WARNINGS -gt 0 ]] && echo -e "${YELLOW}Plus $WARNINGS warnings to review${NC}"
    exit 1
elif [[ $WARNINGS -gt 0 ]]; then
    echo -e "${YELLOW}READY with $WARNINGS warnings${NC}"
    echo "Consider fixing warnings before deploy"
    exit 0
else
    echo -e "${GREEN}READY: All pre-deploy checks passed ✓${NC}"
    exit 0
fi
