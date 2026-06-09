# Plan: CodeRabbit PR #2 Fixes (Round 2)

## Summary

CodeRabbit identified **2 additional issues** after our first round of fixes.

---

## Issues to Fix

### 1. `m` - Unknown verification types emit false "VERIFIED"
**File:** `m` (lines 61-77)
**Severity:** Minor

**Problem:** If an unsupported type is passed to `verify()`, `result` stays `0` and emits a success signal even though no check ran.

**Fix:** Add a default `*)` case that sets `result=2` and prints an error.

```bash
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
```

**Verdict:** CodeRabbit is correct. This prevents false positives for typos like `./m verify iu`.

---

### 2. `scripts/check-deploy.sh` - SOURCE_TIME breaks on macOS
**File:** `scripts/check-deploy.sh` (lines 96-107)
**Severity:** Major

**Problem:** `SOURCE_TIME` uses GNU `stat -c` only, which doesn't exist on macOS. Also, the result can be empty, causing false "build is up to date" messages.

**Fix:** Add BSD `stat -f %m` fallback and default to `0` when empty.

```bash
# Check which stat syntax works (GNU vs BSD)
if stat -c %Y . >/dev/null 2>&1; then
    SOURCE_TIME=$(find . \( -name "*.ts" -o -name "*.tsx" \) -type f | head -100 | xargs stat -c %Y 2>/dev/null | sort -rn | head -1)
else
    SOURCE_TIME=$(find . \( -name "*.ts" -o -name "*.tsx" \) -type f | head -100 | xargs stat -f %m 2>/dev/null | sort -rn | head -1)
fi
SOURCE_TIME=${SOURCE_TIME:-0}
```

**Verdict:** CodeRabbit is correct. This aligns with our goal of macOS portability.

---

## Stories

### Story 1: Add default case to verify() in `m`
- [ ] Add `*)` case that sets result=2 and prints error
- [ ] Test with unknown type like `./m verify foo`

### Story 2: Fix SOURCE_TIME portability in check-deploy.sh
- [ ] Add GNU vs BSD stat detection
- [ ] Default SOURCE_TIME to 0 when empty
- [ ] Test on macOS

---

## Signal

<cipher>PLANNED:2</cipher>
