#!/bin/bash
# check-api.sh - Verify API endpoints respond correctly
# Exit code 1 = issues found, 0 = clean

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

BASE_URL="${1:-http://localhost:3000}"
ISSUES=0
TESTED=0

echo "╔════════════════════════════════════════════╗"
echo "║         API ENDPOINT VERIFICATION          ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "Base URL: $BASE_URL"
echo ""

# Start server if not running
SERVER_PID=""
if ! curl -s "$BASE_URL" > /dev/null 2>&1; then
    echo "Starting server..."
    npm run dev > /dev/null 2>&1 &
    SERVER_PID=$!
    sleep 10
fi

cleanup() {
    if [[ -n "$SERVER_PID" ]]; then
        kill $SERVER_PID 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Test an endpoint
test_endpoint() {
    local method="$1"
    local path="$2"
    local expected_status="$3"
    local data="$4"
    local auth="$5"

    TESTED=$((TESTED + 1))
    local url="$BASE_URL$path"
    local curl_args="-s -w '%{http_code}' -o /tmp/api_response"

    # Add auth header if provided
    if [[ -n "$auth" ]]; then
        curl_args="$curl_args -H 'Authorization: Bearer $auth'"
    fi

    # Add data for POST/PUT/PATCH
    if [[ -n "$data" ]]; then
        curl_args="$curl_args -H 'Content-Type: application/json' -d '$data'"
    fi

    # Make request
    local status
    case "$method" in
        GET)    status=$(eval curl $curl_args "$url") ;;
        POST)   status=$(eval curl $curl_args -X POST "$url") ;;
        PUT)    status=$(eval curl $curl_args -X PUT "$url") ;;
        PATCH)  status=$(eval curl $curl_args -X PATCH "$url") ;;
        DELETE) status=$(eval curl $curl_args -X DELETE "$url") ;;
    esac

    # Remove quotes from status
    status=$(echo "$status" | tr -d "'")

    if [[ "$status" == "$expected_status" ]]; then
        echo -e "${GREEN}✓ $method $path → $status${NC}"
        return 0
    else
        echo -e "${RED}❌ $method $path → $status (expected $expected_status)${NC}"
        ISSUES=$((ISSUES + 1))
        return 1
    fi
}

# 1. Health check
echo "1. Health endpoints..."
test_endpoint GET "/api/health" "200" || true
test_endpoint GET "/health" "200" || true

# 2. Discover and test API routes
echo ""
echo "2. Discovering API routes..."

# Find all API route files (Next.js App Router)
API_ROUTES=$(find . -path "*/app/api/*" -name "route.ts" -o -path "*/app/api/*" -name "route.js" 2>/dev/null | head -20)

if [[ -n "$API_ROUTES" ]]; then
    echo "   Found $(echo "$API_ROUTES" | wc -l | tr -d ' ') API routes"
    echo ""
    echo "3. Testing discovered routes..."

    for route_file in $API_ROUTES; do
        # Convert file path to API path
        # ./app/api/users/route.ts → /api/users
        api_path=$(echo "$route_file" | sed 's|.*/app||' | sed 's|/route\.[tj]s||')

        # Check which methods are exported
        if grep -q "export.*GET\|export async function GET" "$route_file" 2>/dev/null; then
            test_endpoint GET "$api_path" "200" || test_endpoint GET "$api_path" "401" || true
        fi
    done
fi

# 3. Test common API patterns
echo ""
echo "4. Testing common patterns..."

# Public endpoints (should return 200)
test_endpoint GET "/api/health" "200" || true

# Auth-required endpoints (should return 401 without auth)
test_endpoint GET "/api/users" "401" || test_endpoint GET "/api/users" "200" || true
test_endpoint GET "/api/me" "401" || test_endpoint GET "/api/me" "200" || true

# Validation endpoints (should return 400 on bad data)
test_endpoint POST "/api/auth/login" "400" '{"email":""}' || true

# 4. Check for 500 errors
echo ""
echo "5. Checking for 500 errors..."
FIVE_HUNDRED=0
for route_file in $API_ROUTES; do
    api_path=$(echo "$route_file" | sed 's|.*/app||' | sed 's|/route\.[tj]s||')
    status=$(curl -s -o /dev/null -w '%{http_code}' "$BASE_URL$api_path" 2>/dev/null)
    if [[ "$status" == "500" ]]; then
        echo -e "${RED}❌ 500 error: $api_path${NC}"
        FIVE_HUNDRED=$((FIVE_HUNDRED + 1))
    fi
done

if [[ $FIVE_HUNDRED -eq 0 ]]; then
    echo -e "${GREEN}✓ No 500 errors found${NC}"
else
    echo -e "${RED}❌ Found $FIVE_HUNDRED endpoints returning 500${NC}"
    ISSUES=$((ISSUES + FIVE_HUNDRED))
fi

# Summary
echo ""
echo "════════════════════════════════════════════"
echo "Tested: $TESTED endpoints"
if [[ $ISSUES -gt 0 ]]; then
    echo -e "${RED}FAILED: $ISSUES issues found${NC}"
    exit 1
else
    echo -e "${GREEN}PASSED: All API endpoints responding${NC}"
    exit 0
fi
