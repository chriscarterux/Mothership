# Plan: CodeRabbit PR #2 Fixes

## Summary

CodeRabbit identified **7 actionable issues** across 5 files. All suggestions are valid and should be fixed.

---

## Issues to Fix

### 1. `m` - CRITICAL: `((FAIL_COUNT++))` exits script under `set -e`
**File:** `m` (lines 118-139)
**Severity:** Critical

**Problem:** With `set -e`, `((FAIL_COUNT++))` returns exit code 1 when FAIL_COUNT is 0 (because 0 is falsy in bash arithmetic). This causes immediate script exit.

**Fix:**
```bash
# Change from:
((FAIL_COUNT++))
# To:
FAIL_COUNT=$((FAIL_COUNT + 1))
```

**Verdict:** CodeRabbit is correct. This is a real bug.

---

### 2. `scripts/check-database.sh` - Raw .env export preserves quotes/CRLF
**File:** `scripts/check-database.sh` (lines 23-27)
**Severity:** Major

**Problem:** `export "$line"` keeps surrounding quotes and `\r` characters, making DATABASE_URL invalid.

**Fix:**
```bash
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^DATABASE_URL= ]] || continue
    value=${line#DATABASE_URL=}
    value=${value%$'\r'}
    value=${value#\"}; value=${value%\"}
    value=${value#\'}; value=${value%\'}
    export DATABASE_URL="$value"
    break
done < .env
```

**Verdict:** CodeRabbit is correct. This prevents issues with quoted values in .env files.

---

### 3. `scripts/check-deploy.sh` - `ls | grep` is fragile (line 69-73)
**File:** `scripts/check-deploy.sh`
**Severity:** Minor

**Problem:** `ls ... | grep -q .` fails on filenames with special characters.

**Fix:**
```bash
# Change from:
if ls app/api/*stripe* pages/api/*stripe* src/**/stripe* 2>/dev/null | grep -q .; then

# To:
if compgen -G "app/api/*stripe*" > /dev/null 2>&1 || \
   compgen -G "pages/api/*stripe*" > /dev/null 2>&1 || \
   find src -name "*stripe*" -print -quit 2>/dev/null | grep -q .; then
```

**Verdict:** CodeRabbit is correct. More robust file detection.

---

### 4. `scripts/check-deploy.sh` - TABLE_COUNT may be empty (line 180-186)
**File:** `scripts/check-deploy.sh`
**Severity:** Minor

**Problem:** If psql fails, TABLE_COUNT could be empty, causing `-eq` comparison to fail.

**Fix:**
```bash
# Change from:
if [[ "$TABLE_COUNT" -eq 0 ]]; then

# To:
if [[ -z "$TABLE_COUNT" || "$TABLE_COUNT" -eq 0 ]]; then
```

**Verdict:** CodeRabbit is correct. Defensive check for empty values.

---

### 5. `scripts/check-deploy.sh` - `ss` is Linux-only (line 200-206)
**File:** `scripts/check-deploy.sh`
**Severity:** Minor

**Problem:** `ss` command doesn't exist on macOS.

**Fix:**
```bash
# Use lsof for portability (works on Linux and macOS)
if lsof -iTCP:$OLLAMA_PORT -sTCP:LISTEN 2>/dev/null | grep -q "127.0.0.1\|localhost"; then
    echo -e "${RED}...${NC}"
elif lsof -iTCP:$OLLAMA_PORT -sTCP:LISTEN 2>/dev/null | grep -q "\*:"; then
    echo -e "${GREEN}...${NC}"
else
    echo -e "${YELLOW}...${NC}"
fi
```

**Verdict:** CodeRabbit is correct. This aligns with the PR's stated goal of macOS portability.

---

### 6. `scripts/check-integrations.sh` - Same `ss` issue (line 105-114)
**File:** `scripts/check-integrations.sh`
**Severity:** Minor

**Problem:** Same Linux-only `ss` command issue.

**Fix:** Same as #5 - use `lsof` instead.

**Verdict:** CodeRabbit is correct.

---

### 7. `ship` - Fallback for empty type (line 113-115)
**File:** `ship`
**Severity:** Minor

**Problem:** `|| echo "unknown"` doesn't run because pipeline exit status comes from `tr`, not `grep`.

**Fix:**
```bash
# Change from:
local type=$(echo "$next" | grep -Eo '\[(TYPE|ui|api|database|integration|fullstack)\]' | tr -d '[]' || echo "unknown")

# To:
local type=$(echo "$next" | grep -Eo '\[(TYPE|ui|api|database|integration|fullstack)\]' | tr -d '[]')
type=${type:-unknown}
```

**Verdict:** CodeRabbit is correct. The `|| echo "unknown"` was ineffective.

---

## Nitpicks (Optional)

### N1. Broaden empty-arrow detection in `check-wiring.sh`
**Suggestion:** Use regex `\(\)\s*=>\s*\{\s*\}` to catch whitespace variants.
**Verdict:** Nice-to-have but not critical. Current pattern catches common cases.

### N2. Safe .env parsing in `verify-all.sh` and `check-integrations.sh`
**Suggestion:** Use BASH_REMATCH for more explicit parsing.
**Verdict:** Current approach works. Low priority.

### N3. Build freshness check portability in `check-deploy.sh`
**Suggestion:** Use `find -newer` instead of `stat` timestamps.
**Verdict:** Good idea but requires more testing. Could address in future PR.

---

## Stories

### Story 1: Fix critical FAIL_COUNT bug in `m`
- [ ] Replace `((FAIL_COUNT++))` with `FAIL_COUNT=$((FAIL_COUNT + 1))` (2 occurrences)
- [ ] Test quick-check mode with build/test failures

### Story 2: Fix .env parsing in database script
- [ ] Update `scripts/check-database.sh` to properly parse DATABASE_URL
- [ ] Strip quotes and CRLF from value

### Story 3: Fix Stripe file detection in check-deploy.sh
- [ ] Replace `ls | grep` with `compgen`/`find`
- [ ] Add TABLE_COUNT empty check

### Story 4: Replace `ss` with `lsof` for macOS portability
- [ ] Update `scripts/check-deploy.sh` Ollama binding check
- [ ] Update `scripts/check-integrations.sh` Ollama binding check

### Story 5: Fix type fallback in `ship`
- [ ] Use parameter expansion `${type:-unknown}` instead of `|| echo`

---

## Signal

<cipher>PLANNED:5</cipher>
