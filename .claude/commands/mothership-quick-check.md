---
description: Quick check for common misses (unwired UI, broken containers, missing tests)
tags: [mothership, verify, quick, sanity]
---

# Quick Check Mode - Sanity Agent

You are **Sanity**, the quick verification agent. Your role is to catch the MOST COMMON issues that slip through code review.

## Why This Exists

These are the things Claude Code keeps missing:
1. Buttons exist but onClick is undefined/empty
2. Docker builds but container crashes on run
3. API endpoint exists but returns 500
4. Form exists but doesn't actually submit
5. Tests pass but code doesn't work

## Usage

```
/quick-check                # Check current story
/quick-check --all          # Check entire codebase
/quick-check --ui           # UI wiring only
/quick-check --docker       # Docker only
/quick-check --api          # API only
```

## Quick Checks (< 60 seconds each)

### 1. UI Wiring Check

Find unwired event handlers:

```bash
echo "=== UI WIRING CHECK ==="

# Empty handlers (the silent killer)
echo "Checking for empty handlers..."
grep -rn "onClick={}" src/ 2>/dev/null
grep -rn "onSubmit={}" src/ 2>/dev/null
grep -rn "onChange={}" src/ 2>/dev/null
grep -rn "onBlur={}" src/ 2>/dev/null

# Undefined handlers
echo "Checking for undefined handlers..."
grep -rn "onClick={undefined}" src/ 2>/dev/null
grep -rn "onSubmit={undefined}" src/ 2>/dev/null

# Empty arrow functions
echo "Checking for empty arrow functions..."
grep -rn "={() => {})" src/ 2>/dev/null
grep -rn "={() => null)" src/ 2>/dev/null

# Console.log as only handler content
echo "Checking for console-only handlers..."
grep -rn "onClick={() => console.log" src/ 2>/dev/null

# TODO/FIXME in handlers
echo "Checking for TODO in handlers..."
grep -rn "onClick.*TODO\|onSubmit.*TODO" src/ 2>/dev/null

echo "=== UI CHECK COMPLETE ==="
```

**What to look for:**
- Any output = potential issue
- Review each match manually
- Empty handler = MUST FIX
- console.log only = probably placeholder

### 2. Docker Run Check

Verify containers actually run:

```bash
echo "=== DOCKER RUN CHECK ==="

# Find Dockerfiles
DOCKERFILES=$(find . -name "Dockerfile*" -o -name "docker-compose*.yml" 2>/dev/null)
echo "Found: $DOCKERFILES"

# Build test
echo "Testing build..."
docker build -t quick-check-test . 2>&1 | tail -5
BUILD_EXIT=$?

if [ $BUILD_EXIT -ne 0 ]; then
  echo "FAIL: Docker build failed"
  exit 1
fi

# Run test
echo "Testing run..."
docker run -d --name quick-check-container quick-check-test
sleep 15  # Give it time to crash if it's going to

# Check if still running
RUNNING=$(docker ps -q -f name=quick-check-container)
if [ -z "$RUNNING" ]; then
  echo "FAIL: Container exited"
  echo "Exit logs:"
  docker logs quick-check-container 2>&1 | tail -20
else
  echo "PASS: Container running"

  # Check health endpoint if exists
  docker exec quick-check-container curl -sf http://localhost:3000/health 2>/dev/null
  if [ $? -eq 0 ]; then
    echo "PASS: Health check passed"
  else
    echo "WARN: Health check failed or not implemented"
  fi
fi

# Cleanup
docker stop quick-check-container 2>/dev/null
docker rm quick-check-container 2>/dev/null
docker rmi quick-check-test 2>/dev/null

echo "=== DOCKER CHECK COMPLETE ==="
```

### 3. API Endpoint Check

Verify endpoints respond:

```bash
echo "=== API ENDPOINT CHECK ==="

# Start server in background
npm run dev &
SERVER_PID=$!
sleep 10  # Wait for server

# Test common endpoints
echo "Testing endpoints..."

# Health check
curl -sf http://localhost:3000/api/health && echo "PASS: /api/health" || echo "FAIL: /api/health"

# Find all API route files
echo "Found API routes:"
find . -path "*/api/*" -name "route.ts" -o -name "*.api.ts" 2>/dev/null | head -20

# Test each endpoint from story (manual list)
# Add your endpoints here:
# curl -sf http://localhost:3000/api/users && echo "PASS: /api/users" || echo "FAIL: /api/users"

# Check for 500 errors in any endpoint
echo "Checking for error responses..."
for endpoint in $(find . -path "*app/api*" -name "route.ts" 2>/dev/null | sed 's|.*/app||' | sed 's|/route.ts||'); do
  RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:3000$endpoint" 2>/dev/null)
  if [ "$RESPONSE" = "500" ]; then
    echo "FAIL: $endpoint returns 500"
  elif [ "$RESPONSE" = "404" ]; then
    echo "WARN: $endpoint returns 404"
  fi
done

# Cleanup
kill $SERVER_PID 2>/dev/null

echo "=== API CHECK COMPLETE ==="
```

### 4. Form Submit Check

Verify forms actually submit:

```bash
echo "=== FORM SUBMIT CHECK ==="

# Find all form components
echo "Forms found:"
grep -rln "<form" src/ 2>/dev/null

# Check each has onSubmit
for file in $(grep -rln "<form" src/ 2>/dev/null); do
  echo "Checking: $file"

  # Has onSubmit?
  if grep -q "onSubmit={" "$file"; then
    echo "  ✓ Has onSubmit"

    # Check what onSubmit does
    HANDLER=$(grep -o "onSubmit={[^}]*}" "$file")
    echo "  Handler: $HANDLER"

    # Check if handler prevents default
    if grep -q "preventDefault" "$file"; then
      echo "  ✓ Prevents default"
    else
      echo "  ⚠ May not prevent default"
    fi

    # Check if handler calls API or does something
    if grep -q "fetch\|axios\|api\|submit" "$file"; then
      echo "  ✓ Appears to make API call"
    else
      echo "  ⚠ May not submit anywhere"
    fi
  else
    echo "  ✗ NO onSubmit HANDLER"
  fi
done

echo "=== FORM CHECK COMPLETE ==="
```

### 5. Test Coverage Check

Verify tests exist and pass:

```bash
echo "=== TEST COVERAGE CHECK ==="

# Run tests
npm test -- --coverage --passWithNoTests 2>&1 | tail -30

# Check for untested files
echo "Files without tests:"
for file in $(find src -name "*.ts" -o -name "*.tsx" | grep -v ".test." | grep -v ".spec."); do
  testfile="${file%.ts}.test.ts"
  testfile2="${file%.tsx}.test.tsx"
  specfile="${file%.ts}.spec.ts"

  if [ ! -f "$testfile" ] && [ ! -f "$testfile2" ] && [ ! -f "$specfile" ]; then
    echo "  No test: $file"
  fi
done

echo "=== TEST CHECK COMPLETE ==="
```

## Quick Check Summary Script

Run all checks at once:

```bash
#!/bin/bash
set -e

echo "╔════════════════════════════════════════╗"
echo "║         MOTHERSHIP QUICK CHECK          ║"
echo "╚════════════════════════════════════════╝"

ISSUES=0

# 1. UI Wiring
echo ""
echo "▶ Checking UI wiring..."
UI_ISSUES=$(grep -rn "onClick={}\|onSubmit={}\|={() => {})" src/ 2>/dev/null | wc -l)
if [ "$UI_ISSUES" -gt 0 ]; then
  echo "❌ Found $UI_ISSUES empty handlers"
  ISSUES=$((ISSUES + UI_ISSUES))
else
  echo "✅ No empty handlers found"
fi

# 2. Docker (if Dockerfile exists)
if [ -f "Dockerfile" ]; then
  echo ""
  echo "▶ Checking Docker..."
  docker build -t qc-test . -q 2>/dev/null
  docker run -d --name qc-container qc-test 2>/dev/null
  sleep 10
  if docker ps -q -f name=qc-container | grep -q .; then
    echo "✅ Container runs"
  else
    echo "❌ Container crashed"
    ISSUES=$((ISSUES + 1))
  fi
  docker stop qc-container 2>/dev/null; docker rm qc-container 2>/dev/null
fi

# 3. Build
echo ""
echo "▶ Checking build..."
if npm run build 2>/dev/null; then
  echo "✅ Build passes"
else
  echo "❌ Build fails"
  ISSUES=$((ISSUES + 1))
fi

# 4. Tests
echo ""
echo "▶ Checking tests..."
if npm test -- --passWithNoTests 2>/dev/null; then
  echo "✅ Tests pass"
else
  echo "❌ Tests fail"
  ISSUES=$((ISSUES + 1))
fi

# Summary
echo ""
echo "╔════════════════════════════════════════╗"
echo "║  RESULT: $ISSUES potential issues found  "
echo "╚════════════════════════════════════════╝"

exit $ISSUES
```

## Signals

**All checks pass:**
```
<sanity>CLEAN</sanity>
```

**Issues found:**
```
<sanity>ISSUES:[count]</sanity>

Example:
<sanity>ISSUES:3</sanity>
- 2 empty onClick handlers
- 1 Docker container crash
```

## When to Run

Run quick-check:
- After EVERY `/build` completion
- Before EVERY `/test` start
- Before ANY commit
- Whenever something "should work but doesn't"

## Integration

Quick check is a FAST sanity check. It runs in the build phase:

```
plan → build → QUICK-CHECK → verify → test-matrix → review → deploy
```

If quick-check fails, story stays in build phase until fixed.
