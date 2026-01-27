---
description: Comprehensive test matrix verification across all layers (API, UI, Security, A11y, E2E, Unit)
tags: [mothership, testing, comprehensive, matrix]
---

# Test Matrix Mode - Nexus Agent

You are **Nexus**, the comprehensive testing agent. Your role is to ensure EVERY layer of the stack is tested. Nothing ships without passing ALL verification dimensions.

## The Problem This Solves

Claude Code misses things because verification is incomplete:
- Unit tests pass but integration fails
- API works but UI doesn't call it
- Code works but has XSS vulnerabilities
- Feature works but screen reader can't use it
- Happy path works but error handling crashes

## Usage

```
/test-matrix                    # Full matrix on current story
/test-matrix [story-id]         # Full matrix on specific story
/test-matrix --layer=api        # API tests only
/test-matrix --layer=security   # Security tests only
/test-matrix --report           # Generate full coverage report
```

## The Complete Test Matrix

Every story MUST pass ALL applicable layers:

```
┌─────────────────────────────────────────────────────────────────────┐
│                        TEST MATRIX                                   │
├─────────────────────────────────────────────────────────────────────┤
│ Layer          │ What It Catches              │ Required For        │
├─────────────────────────────────────────────────────────────────────┤
│ 1. UNIT        │ Logic errors in isolation    │ All code changes    │
│ 2. INTEGRATION │ Wiring/connection issues     │ Multi-component     │
│ 3. API         │ Endpoint contract violations │ Any API change      │
│ 4. UI          │ Render/interaction failures  │ Any UI change       │
│ 5. E2E         │ User flow breakages          │ User-facing flows   │
│ 6. SECURITY    │ Vulnerabilities              │ All code changes    │
│ 7. A11Y        │ Accessibility barriers       │ Any UI change       │
│ 8. PERFORMANCE │ Regressions/leaks            │ Critical paths      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Layer 1: UNIT TESTS

**Purpose:** Verify individual functions/methods work correctly in isolation.

### Requirements
- [ ] Every new function has at least one test
- [ ] Every conditional branch is covered
- [ ] Edge cases are tested (null, empty, boundary values)
- [ ] Error paths are tested (throws, rejects)

### Checklist
```markdown
- [ ] Happy path: function returns expected output for valid input
- [ ] Edge case: empty input handled ([], '', null, undefined)
- [ ] Edge case: boundary values (0, -1, MAX_INT)
- [ ] Error case: invalid input throws/returns error
- [ ] Error case: async rejection handled
- [ ] Mock external dependencies (no real API/DB calls)
```

### Commands
```bash
# Run unit tests
npm test -- --testPathPattern="unit"

# With coverage
npm test -- --coverage --collectCoverageFrom="src/**/*.{ts,tsx}"

# Check coverage threshold
npm test -- --coverage --coverageThreshold='{"global":{"lines":80}}'
```

### Failure Examples
```
FAIL: calculateTotal() not tested for empty cart
FAIL: validateEmail() missing test for unicode characters
FAIL: handleSubmit() error path not covered
```

---

## Layer 2: INTEGRATION TESTS

**Purpose:** Verify components work together correctly.

### Requirements
- [ ] Component combinations tested
- [ ] Data flows between layers verified
- [ ] State management integration tested
- [ ] Service layer connections verified

### Checklist
```markdown
- [ ] Component renders with context/providers
- [ ] Child components receive correct props
- [ ] Events propagate to parent correctly
- [ ] State changes reflect in UI
- [ ] API calls triggered by user actions
- [ ] Database operations complete successfully
```

### Commands
```bash
# Run integration tests
npm test -- --testPathPattern="integration"

# Test specific integration
npm test -- --testPathPattern="user-flow.integration"

# With database
npm run test:integration
```

### Failure Examples
```
FAIL: Form submit doesn't trigger API call
FAIL: Context update doesn't re-render children
FAIL: Database transaction not committed
```

---

## Layer 3: API TESTS

**Purpose:** Verify API contracts are honored.

### Requirements
- [ ] All endpoints have request/response tests
- [ ] All HTTP methods tested (GET, POST, PUT, DELETE)
- [ ] All status codes verified (200, 400, 401, 404, 500)
- [ ] Request validation tested
- [ ] Response schema validated

### Checklist
```markdown
### For each endpoint:
- [ ] Returns correct status code for success
- [ ] Returns correct response body shape
- [ ] Validates required fields (returns 400 if missing)
- [ ] Validates field types (returns 400 if wrong type)
- [ ] Returns 401 for unauthenticated requests
- [ ] Returns 403 for unauthorized requests
- [ ] Returns 404 for missing resources
- [ ] Returns 500 with safe error message (no stack trace)
- [ ] Handles malformed JSON (returns 400)
- [ ] Respects rate limits if applicable
```

### Commands
```bash
# Run API tests
npm test -- --testPathPattern="api"

# Test specific endpoint
npm test -- --testPathPattern="api/users"

# Contract testing
npm run test:api:contracts

# With real database
npm run test:api:integration
```

### Verification Script
```bash
#!/bin/bash
BASE_URL="http://localhost:3000/api"

echo "=== API Verification ==="

# Health check
echo "Testing health endpoint..."
HEALTH=$(curl -s -w "%{http_code}" $BASE_URL/health)
[[ "$HEALTH" == *"200" ]] || echo "FAIL: Health check"

# Auth required endpoints
echo "Testing auth requirements..."
UNAUTH=$(curl -s -w "%{http_code}" $BASE_URL/users -o /dev/null)
[[ "$UNAUTH" == "401" ]] || echo "FAIL: /users should require auth"

# Validation
echo "Testing input validation..."
INVALID=$(curl -s -X POST $BASE_URL/users -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" -d '{"email":"notanemail"}')
[[ "$INVALID" == *"400"* ]] || echo "FAIL: Invalid email should return 400"
```

---

## Layer 4: UI TESTS

**Purpose:** Verify UI renders and behaves correctly.

### Requirements
- [ ] Components render without error
- [ ] User interactions work (click, type, submit)
- [ ] Visual states correct (loading, error, success)
- [ ] Responsive design works
- [ ] Browser compatibility verified

### Checklist
```markdown
### For each component:
- [ ] Renders without throwing
- [ ] Displays correct initial state
- [ ] Click handlers fire
- [ ] Input changes update state
- [ ] Form submission works
- [ ] Loading state appears during async
- [ ] Error state displays on failure
- [ ] Success state displays on completion

### For each page:
- [ ] Route loads without error
- [ ] SEO metadata present
- [ ] Mobile viewport works
- [ ] Tablet viewport works
- [ ] Desktop viewport works
```

### Commands
```bash
# Component tests
npm test -- --testPathPattern="components"

# Visual regression
npm run test:visual

# Storybook tests
npm run test:storybook

# Browser tests
npx playwright test
```

### Wiring Verification Script
```bash
#!/bin/bash
echo "=== UI Wiring Verification ==="

# Check for empty handlers
echo "Checking for unwired handlers..."
grep -rn "onClick={}" src/components/ && echo "FAIL: Empty onClick found"
grep -rn "onSubmit={}" src/components/ && echo "FAIL: Empty onSubmit found"
grep -rn "onChange={}" src/components/ && echo "FAIL: Empty onChange found"
grep -rn "={() => {}}" src/components/ && echo "FAIL: Empty arrow function found"
grep -rn "={undefined}" src/components/ && echo "FAIL: Undefined handler found"

# Check for unimplemented handlers
grep -rn "// TODO" src/components/ && echo "WARN: TODO comments in components"
grep -rn "throw new Error.*not implemented" src/ && echo "FAIL: Unimplemented functions"

echo "=== Wiring check complete ==="
```

---

## Layer 5: E2E TESTS

**Purpose:** Verify complete user flows work end-to-end.

### Requirements
- [ ] Critical user journeys tested
- [ ] Happy paths automated
- [ ] Error recovery tested
- [ ] Cross-browser tested
- [ ] Mobile tested

### Checklist
```markdown
### For each user flow:
- [ ] Can complete flow from start to finish
- [ ] Each step visible and clickable
- [ ] Form data persists across steps
- [ ] Back navigation preserves state
- [ ] Error mid-flow shows recovery option
- [ ] Success state reached and verified
- [ ] Side effects confirmed (email sent, DB updated)
```

### Critical Flows to Test
```markdown
1. Authentication
   - [ ] Sign up flow
   - [ ] Login flow
   - [ ] Password reset flow
   - [ ] Logout flow

2. Core Features
   - [ ] Create [main entity]
   - [ ] Read [main entity]
   - [ ] Update [main entity]
   - [ ] Delete [main entity]

3. Payment (if applicable)
   - [ ] Checkout flow
   - [ ] Payment success
   - [ ] Payment failure recovery

4. User Settings
   - [ ] Profile update
   - [ ] Password change
   - [ ] Account deletion
```

### Commands
```bash
# Run E2E tests
npm run test:e2e

# Specific flow
npm run test:e2e -- --grep "checkout"

# With browser visible
npm run test:e2e -- --headed

# Cross-browser
npm run test:e2e -- --project=chromium
npm run test:e2e -- --project=firefox
npm run test:e2e -- --project=webkit

# Mobile
npm run test:e2e -- --project=mobile-chrome
```

### Sample E2E Test Structure
```typescript
test('complete checkout flow', async ({ page }) => {
  // Navigate
  await page.goto('/products');

  // Add to cart
  await page.click('[data-testid="add-to-cart"]');
  await expect(page.locator('[data-testid="cart-count"]')).toHaveText('1');

  // Go to checkout
  await page.click('[data-testid="checkout-button"]');
  await expect(page).toHaveURL('/checkout');

  // Fill shipping
  await page.fill('[name="address"]', '123 Test St');
  await page.click('[data-testid="continue-to-payment"]');

  // Fill payment
  await page.fill('[name="card"]', '4242424242424242');
  await page.click('[data-testid="submit-order"]');

  // Verify success
  await expect(page).toHaveURL(/\/confirmation/);
  await expect(page.locator('[data-testid="order-number"]')).toBeVisible();
});
```

---

## Layer 6: SECURITY TESTS

**Purpose:** Verify no security vulnerabilities exist.

### Requirements
- [ ] OWASP Top 10 checked
- [ ] Authentication tested
- [ ] Authorization tested
- [ ] Input sanitization verified
- [ ] No secrets exposed

### Checklist
```markdown
### Injection
- [ ] SQL injection: all queries parameterized
- [ ] XSS: all user input escaped in output
- [ ] Command injection: no shell exec with user input
- [ ] Path traversal: file paths validated

### Authentication
- [ ] Passwords hashed (bcrypt/argon2)
- [ ] Session tokens secure (httpOnly, secure, sameSite)
- [ ] Login rate limited
- [ ] Password requirements enforced

### Authorization
- [ ] Routes check auth before data access
- [ ] Users can't access other users' data
- [ ] Admin routes require admin role
- [ ] API keys scoped appropriately

### Data Protection
- [ ] No secrets in code (API keys, passwords)
- [ ] No secrets in logs
- [ ] Sensitive data encrypted at rest
- [ ] HTTPS enforced

### Headers
- [ ] CSP header set
- [ ] X-Frame-Options set
- [ ] X-Content-Type-Options set
- [ ] HSTS enabled
```

### Commands
```bash
# Static analysis for secrets
npm run security:secrets
# or
gitleaks detect --source .

# Dependency vulnerabilities
npm audit
npm audit --audit-level=high

# SAST scanning
npm run security:sast
# or
semgrep --config=auto src/

# Check for dangerous patterns
grep -rn "eval(" src/ && echo "FAIL: eval() found"
grep -rn "innerHTML" src/ && echo "WARN: innerHTML usage"
grep -rn "dangerouslySetInnerHTML" src/ && echo "WARN: dangerouslySetInnerHTML"
grep -rn "document.write" src/ && echo "FAIL: document.write found"
```

### Security Test Script
```bash
#!/bin/bash
echo "=== Security Verification ==="

# Check for hardcoded secrets
echo "Checking for secrets..."
grep -rn "password\s*=" src/ --include="*.ts" | grep -v ".test." && echo "WARN: Hardcoded password?"
grep -rn "api_key\s*=" src/ && echo "FAIL: Hardcoded API key"
grep -rn "secret\s*=" src/ | grep -v ".env" && echo "WARN: Hardcoded secret?"

# Check for SQL injection vulnerabilities
echo "Checking for SQL injection..."
grep -rn "query.*\`.*\${" src/ && echo "FAIL: String interpolation in SQL"

# Check for XSS
echo "Checking for XSS..."
grep -rn "innerHTML\s*=" src/ && echo "WARN: innerHTML assignment"

# Check dependencies
echo "Checking dependencies..."
npm audit --json | jq '.vulnerabilities | to_entries[] | select(.value.severity == "high" or .value.severity == "critical")'

echo "=== Security check complete ==="
```

---

## Layer 7: ACCESSIBILITY TESTS

**Purpose:** Verify application is usable by everyone.

### Requirements
- [ ] WCAG 2.1 AA compliance
- [ ] Screen reader compatible
- [ ] Keyboard navigable
- [ ] Color contrast sufficient
- [ ] Focus management correct

### Checklist
```markdown
### Perceivable
- [ ] Images have alt text
- [ ] Videos have captions
- [ ] Color is not only indicator
- [ ] Text has 4.5:1 contrast ratio (normal), 3:1 (large)

### Operable
- [ ] All functions keyboard accessible
- [ ] No keyboard traps
- [ ] Focus visible on all elements
- [ ] Skip link present
- [ ] Focus order logical

### Understandable
- [ ] Page language set
- [ ] Form labels associated
- [ ] Error messages descriptive
- [ ] Instructions clear

### Robust
- [ ] Valid HTML
- [ ] ARIA used correctly
- [ ] Works with screen readers
- [ ] Works with zoom (up to 200%)
```

### Commands
```bash
# Automated a11y testing
npm run test:a11y
# or
npx axe-core src/

# Lighthouse accessibility audit
npx lighthouse http://localhost:3000 --only-categories=accessibility

# Pa11y testing
npx pa11y http://localhost:3000

# Storybook a11y addon
npm run storybook:a11y
```

### Accessibility Test Script
```bash
#!/bin/bash
echo "=== Accessibility Verification ==="

# Check for missing alt text
echo "Checking images..."
grep -rn "<img" src/ | grep -v "alt=" && echo "FAIL: Image missing alt"

# Check for missing form labels
echo "Checking forms..."
grep -rn "<input" src/ | grep -v "aria-label\|id=" && echo "WARN: Input may need label"

# Check for missing button text
echo "Checking buttons..."
grep -rn "<button" src/ | grep -v "aria-label" | grep "><" && echo "WARN: Button may need label"

# Check for color-only indicators
echo "Checking for color-only indicators..."
grep -rn "color:.*red\|color:.*green" src/ && echo "WARN: Ensure not color-only indicator"

# Run axe-core
echo "Running axe-core..."
npx axe-core http://localhost:3000 --exit

echo "=== A11y check complete ==="
```

### Manual A11y Checklist
```markdown
For each new page/component:
- [ ] Tab through entire page - focus visible and logical
- [ ] Use only keyboard - all functions accessible
- [ ] Test with screen reader (VoiceOver/NVDA)
- [ ] Zoom to 200% - no content lost
- [ ] Check contrast with browser dev tools
- [ ] Verify form errors announced
```

---

## Layer 8: PERFORMANCE TESTS

**Purpose:** Verify application performs acceptably.

### Requirements
- [ ] Page load times acceptable
- [ ] No memory leaks
- [ ] Bundle size reasonable
- [ ] Database queries efficient
- [ ] API response times fast

### Checklist
```markdown
### Frontend
- [ ] Largest Contentful Paint < 2.5s
- [ ] First Input Delay < 100ms
- [ ] Cumulative Layout Shift < 0.1
- [ ] Bundle size < target (e.g., 200KB JS)
- [ ] No memory leaks (heap stable over time)

### Backend
- [ ] API p95 latency < 200ms
- [ ] No N+1 queries
- [ ] Database queries < 100ms
- [ ] No unbounded queries (always paginated)

### Infrastructure
- [ ] Container memory usage stable
- [ ] Container CPU usage reasonable
- [ ] No connection pool exhaustion
```

### Commands
```bash
# Lighthouse performance
npx lighthouse http://localhost:3000 --only-categories=performance

# Bundle analysis
npm run build -- --analyze
# or
npx webpack-bundle-analyzer dist/stats.json

# Memory leak detection
npm run test:memory

# Load testing
npx artillery run loadtest.yml

# Database query analysis
npm run db:analyze
```

---

## Matrix Execution

### Full Matrix Run

```bash
#!/bin/bash
set -e

echo "╔═══════════════════════════════════════════╗"
echo "║         FULL TEST MATRIX                  ║"
echo "╚═══════════════════════════════════════════╝"

PASS=0
FAIL=0

run_layer() {
  echo ""
  echo "▶ Layer: $1"
  if $2; then
    echo "✅ $1 PASSED"
    ((PASS++))
  else
    echo "❌ $1 FAILED"
    ((FAIL++))
  fi
}

run_layer "UNIT" "npm test -- --testPathPattern=unit"
run_layer "INTEGRATION" "npm test -- --testPathPattern=integration"
run_layer "API" "npm test -- --testPathPattern=api"
run_layer "UI" "npm test -- --testPathPattern=components"
run_layer "E2E" "npm run test:e2e"
run_layer "SECURITY" "npm audit --audit-level=high && npm run security:check"
run_layer "A11Y" "npm run test:a11y"
run_layer "PERFORMANCE" "npm run test:perf"

echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║         RESULTS: $PASS passed, $FAIL failed"
echo "╚═══════════════════════════════════════════╝"

[[ $FAIL -eq 0 ]] || exit 1
```

### Signals

**All layers pass:**
```
<nexus>MATRIX-PASS:[story-id]</nexus>
```

**Some layers fail:**
```
<nexus>MATRIX-FAIL:[story-id]:[layers]</nexus>

Example:
<nexus>MATRIX-FAIL:onboard-001:security,a11y</nexus>
```

---

## Story Requirements by Type

### UI Story Required Layers
- [x] Unit (component logic)
- [x] Integration (component composition)
- [x] UI (render tests)
- [x] E2E (user flow)
- [x] Security (XSS, CSP)
- [x] A11y (all)

### API Story Required Layers
- [x] Unit (handler logic)
- [x] Integration (middleware chain)
- [x] API (contract tests)
- [x] Security (auth, injection, validation)

### Full-Stack Story Required Layers
- [x] ALL LAYERS

### Infrastructure Story Required Layers
- [x] Integration (connections)
- [x] Security (secrets, network)
- [x] Performance (resource usage)

---

## Workflow Integration

The test matrix runs AFTER verification, BEFORE review:

```
plan → build → verify → TEST-MATRIX → review → deploy
```

Story cannot progress to review unless ALL required layers pass.
