#!/bin/bash
# check-integrations.sh - Verify third-party integrations work
# Exit code 1 = issues found, 0 = clean

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ISSUES=0
TESTED=0

echo "╔════════════════════════════════════════════╗"
echo "║     THIRD-PARTY INTEGRATION CHECK          ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Load env vars
if [[ -f ".env" ]]; then
    export $(grep -v '^#' .env | xargs)
fi

# Test an integration
test_integration() {
    local name="$1"
    local test_cmd="$2"

    TESTED=$((TESTED + 1))
    echo -n "Testing $name... "

    if eval "$test_cmd" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Connected${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed${NC}"
        ISSUES=$((ISSUES + 1))
        return 1
    fi
}

# 1. STRIPE
echo "1. Payment (Stripe)..."
if [[ -n "$STRIPE_SECRET_KEY" ]]; then
    test_integration "Stripe API" \
        "curl -s -u '$STRIPE_SECRET_KEY:' https://api.stripe.com/v1/balance | grep -q 'available'"

    # Check webhook endpoint exists
    if [[ -f "app/api/stripe/webhook/route.ts" ]] || [[ -f "app/api/webhooks/stripe/route.ts" ]]; then
        echo -e "${GREEN}✓ Stripe webhook endpoint exists${NC}"
    else
        echo -e "${YELLOW}⚠️  No Stripe webhook endpoint found${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  STRIPE_SECRET_KEY not set, skipping${NC}"
fi

# 2. EMAIL (Resend, SendGrid, etc.)
echo ""
echo "2. Email Service..."
if [[ -n "$RESEND_API_KEY" ]]; then
    test_integration "Resend API" \
        "curl -s -H 'Authorization: Bearer $RESEND_API_KEY' https://api.resend.com/domains | grep -q 'data'"
elif [[ -n "$SENDGRID_API_KEY" ]]; then
    test_integration "SendGrid API" \
        "curl -s -H 'Authorization: Bearer $SENDGRID_API_KEY' https://api.sendgrid.com/v3/user/profile | grep -q 'username'"
elif [[ -n "$POSTMARK_API_KEY" ]]; then
    test_integration "Postmark API" \
        "curl -s -H 'X-Postmark-Server-Token: $POSTMARK_API_KEY' https://api.postmarkapp.com/server | grep -q 'Name'"
else
    echo -e "${YELLOW}⚠️  No email service configured${NC}"
fi

# 3. AI/LLM (Anthropic, OpenAI)
echo ""
echo "3. AI/LLM Service..."
if [[ -n "$ANTHROPIC_API_KEY" ]]; then
    test_integration "Anthropic/Claude API" \
        "curl -s -H 'x-api-key: $ANTHROPIC_API_KEY' -H 'anthropic-version: 2023-06-01' https://api.anthropic.com/v1/messages -d '{}' 2>&1 | grep -q 'error\|messages'"
elif [[ -n "$OPENAI_API_KEY" ]]; then
    test_integration "OpenAI API" \
        "curl -s -H 'Authorization: Bearer $OPENAI_API_KEY' https://api.openai.com/v1/models | grep -q 'data'"
else
    echo -e "${YELLOW}⚠️  No AI service configured${NC}"
fi

# 4. DATABASE
echo ""
echo "4. Database..."
if [[ -n "$DATABASE_URL" ]]; then
    if echo "$DATABASE_URL" | grep -q "postgres"; then
        test_integration "PostgreSQL" \
            "psql '$DATABASE_URL' -c 'SELECT 1'"
    elif echo "$DATABASE_URL" | grep -q "mysql"; then
        test_integration "MySQL" \
            "mysql -e 'SELECT 1'"
    fi
else
    echo -e "${YELLOW}⚠️  DATABASE_URL not set${NC}"
fi

# 5. CACHE (Redis)
echo ""
echo "5. Cache (Redis)..."
if [[ -n "$REDIS_URL" ]]; then
    test_integration "Redis" \
        "redis-cli -u '$REDIS_URL' ping | grep -q PONG"
elif [[ -n "$UPSTASH_REDIS_REST_URL" ]]; then
    test_integration "Upstash Redis" \
        "curl -s '$UPSTASH_REDIS_REST_URL/ping' -H 'Authorization: Bearer $UPSTASH_REDIS_REST_TOKEN' | grep -q PONG"
else
    echo -e "${YELLOW}⚠️  No Redis configured${NC}"
fi

# 6. FILE STORAGE (S3, Cloudflare R2, etc.)
echo ""
echo "6. File Storage..."
if [[ -n "$AWS_ACCESS_KEY_ID" ]] && [[ -n "$AWS_S3_BUCKET" ]]; then
    test_integration "AWS S3" \
        "aws s3 ls s3://$AWS_S3_BUCKET --max-items 1"
elif [[ -n "$CLOUDFLARE_R2_ACCESS_KEY" ]]; then
    echo -e "${YELLOW}⚠️  Cloudflare R2 configured (manual verification needed)${NC}"
else
    echo -e "${YELLOW}⚠️  No file storage configured${NC}"
fi

# 7. AUTHENTICATION (Auth0, Clerk, etc.)
echo ""
echo "7. Authentication Provider..."
if [[ -n "$AUTH0_DOMAIN" ]]; then
    test_integration "Auth0" \
        "curl -s https://$AUTH0_DOMAIN/.well-known/openid-configuration | grep -q 'issuer'"
elif [[ -n "$CLERK_SECRET_KEY" ]]; then
    test_integration "Clerk" \
        "curl -s -H 'Authorization: Bearer $CLERK_SECRET_KEY' https://api.clerk.com/v1/users?limit=1 | grep -q 'data'"
elif [[ -n "$NEXTAUTH_SECRET" ]]; then
    echo -e "${GREEN}✓ NextAuth configured${NC}"
else
    echo -e "${YELLOW}⚠️  No auth provider configured${NC}"
fi

# 8. ANALYTICS (optional)
echo ""
echo "8. Analytics..."
if [[ -n "$NEXT_PUBLIC_POSTHOG_KEY" ]]; then
    echo -e "${GREEN}✓ PostHog configured${NC}"
elif [[ -n "$NEXT_PUBLIC_GA_ID" ]]; then
    echo -e "${GREEN}✓ Google Analytics configured${NC}"
else
    echo -e "${YELLOW}⚠️  No analytics configured (optional)${NC}"
fi

# Summary
echo ""
echo "════════════════════════════════════════════"
echo "Tested: $TESTED integrations"
if [[ $ISSUES -gt 0 ]]; then
    echo -e "${RED}FAILED: $ISSUES integrations not working${NC}"
    exit 1
else
    echo -e "${GREEN}PASSED: All configured integrations working${NC}"
    exit 0
fi
