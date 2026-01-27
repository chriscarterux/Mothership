#!/bin/bash
# check-database.sh - Verify database is configured and accessible
# Exit code 1 = issues found, 0 = clean
# Run in CI or before deployment

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ISSUES=0

echo "╔════════════════════════════════════════════╗"
echo "║         DATABASE VERIFICATION              ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# 1. Check DATABASE_URL is set
echo "1. Checking DATABASE_URL..."
if [[ -z "$DATABASE_URL" ]]; then
    # Try loading from .env
    if [[ -f ".env" ]]; then
        export $(grep -v '^#' .env | grep DATABASE_URL | xargs)
    fi
fi

if [[ -z "$DATABASE_URL" ]]; then
    echo -e "${RED}❌ DATABASE_URL not set${NC}"
    echo "   Set DATABASE_URL in environment or .env file"
    ISSUES=$((ISSUES + 1))
else
    echo -e "${GREEN}✓ DATABASE_URL is set${NC}"
fi

# 2. Check database connectivity
echo ""
echo "2. Checking database connectivity..."
if [[ -n "$DATABASE_URL" ]]; then
    # Try psql for PostgreSQL
    if command -v psql &> /dev/null; then
        if psql "$DATABASE_URL" -c "SELECT 1" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Database connection successful (PostgreSQL)${NC}"
        else
            echo -e "${RED}❌ Cannot connect to database${NC}"
            ISSUES=$((ISSUES + 1))
        fi
    # Try mysql for MySQL
    elif command -v mysql &> /dev/null; then
        # Parse MySQL URL
        if echo "$DATABASE_URL" | grep -q "mysql"; then
            if mysql -e "SELECT 1" > /dev/null 2>&1; then
                echo -e "${GREEN}✓ Database connection successful (MySQL)${NC}"
            else
                echo -e "${RED}❌ Cannot connect to database${NC}"
                ISSUES=$((ISSUES + 1))
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  No database client found (psql/mysql), skipping connection test${NC}"
    fi
fi

# 3. Check migrations are up to date
echo ""
echo "3. Checking migrations..."

# Prisma
if [[ -f "prisma/schema.prisma" ]]; then
    echo "   Detected: Prisma"
    if npx prisma migrate status 2>&1 | grep -q "Database schema is up to date"; then
        echo -e "${GREEN}✓ Prisma migrations up to date${NC}"
    elif npx prisma migrate status 2>&1 | grep -q "Following migration"; then
        echo -e "${RED}❌ Pending Prisma migrations${NC}"
        npx prisma migrate status 2>&1 | grep "Following migration" | head -5
        ISSUES=$((ISSUES + 1))
    else
        echo -e "${YELLOW}⚠️  Could not determine Prisma migration status${NC}"
    fi
fi

# Drizzle
if [[ -f "drizzle.config.ts" ]] || [[ -f "drizzle.config.js" ]]; then
    echo "   Detected: Drizzle"
    if command -v drizzle-kit &> /dev/null; then
        # Drizzle doesn't have a built-in status command, check for pending
        echo -e "${YELLOW}⚠️  Drizzle detected - run 'drizzle-kit push' to verify${NC}"
    fi
fi

# Knex
if [[ -f "knexfile.js" ]] || [[ -f "knexfile.ts" ]]; then
    echo "   Detected: Knex"
    if npx knex migrate:status 2>&1 | grep -q "No Coverage"; then
        echo -e "${GREEN}✓ Knex migrations up to date${NC}"
    else
        PENDING=$(npx knex migrate:status 2>&1 | grep -c "pending" || echo "0")
        if [[ "$PENDING" -gt 0 ]]; then
            echo -e "${RED}❌ $PENDING pending Knex migrations${NC}"
            ISSUES=$((ISSUES + 1))
        fi
    fi
fi

# Generic migration check via npm scripts
if [[ -f "package.json" ]]; then
    if grep -q '"db:status"' package.json; then
        echo "   Running: npm run db:status"
        npm run db:status 2>&1 | tail -5
    elif grep -q '"migrate:status"' package.json; then
        echo "   Running: npm run migrate:status"
        npm run migrate:status 2>&1 | tail -5
    fi
fi

# 4. Check required tables exist
echo ""
echo "4. Checking required tables..."

# Load required tables from config or use defaults
REQUIRED_TABLES_FILE=".mothership/required-tables.txt"
if [[ -f "$REQUIRED_TABLES_FILE" ]]; then
    mapfile -t REQUIRED_TABLES < "$REQUIRED_TABLES_FILE"
else
    # Common tables to check
    REQUIRED_TABLES=("users" "accounts" "sessions")
fi

if [[ -n "$DATABASE_URL" ]] && command -v psql &> /dev/null; then
    for table in "${REQUIRED_TABLES[@]}"; do
        EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = '$table')" 2>/dev/null | tr -d ' ')
        if [[ "$EXISTS" == "t" ]]; then
            echo -e "${GREEN}✓ Table exists: $table${NC}"
        else
            echo -e "${RED}❌ Table missing: $table${NC}"
            ISSUES=$((ISSUES + 1))
        fi
    done
fi

# 5. Check database can write (not read-only)
echo ""
echo "5. Checking write access..."
if [[ -n "$DATABASE_URL" ]] && command -v psql &> /dev/null; then
    # Try to create and drop a test table
    if psql "$DATABASE_URL" -c "CREATE TABLE IF NOT EXISTS _mothership_test (id int); DROP TABLE _mothership_test;" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Database is writable${NC}"
    else
        echo -e "${RED}❌ Database is read-only or write failed${NC}"
        ISSUES=$((ISSUES + 1))
    fi
fi

# Summary
echo ""
echo "════════════════════════════════════════════"
if [[ $ISSUES -gt 0 ]]; then
    echo -e "${RED}FAILED: $ISSUES database issues found${NC}"
    exit 1
else
    echo -e "${GREEN}PASSED: Database verification complete${NC}"
    exit 0
fi
