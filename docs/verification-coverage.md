# Verification Coverage

What Mothership checks vs what can still break.

## Complete Verification Matrix

| Area | Script | What It Catches |
|------|--------|-----------------|
| **UI Wiring** | `check-wiring.sh` | Empty onClick, onSubmit, onChange handlers |
| **Build** | `npm run build` | TypeScript errors, import failures |
| **Lint** | `npm run lint` | Code style, unused vars |
| **Tests** | `npm test` | Logic errors, regressions |
| **Docker** | `verify-docker.sh` | Container crashes, health check failures |
| **Env Vars** | `check-env.sh` | Missing required variables |
| **Database** | `check-database.sh` | Connection failures, missing tables, pending migrations |
| **APIs** | `check-api.sh` | 500 errors, missing routes, broken endpoints |
| **Integrations** | `check-integrations.sh` | Stripe, email, AI, storage not working |

## What Each Check Covers

### check-wiring.sh
```
✓ Empty onClick={}
✓ Empty onSubmit={}
✓ Empty onChange={}
✓ Empty arrow functions (() => {})
✓ Undefined handlers
✗ Handlers that exist but do wrong thing (need tests)
```

### check-database.sh
```
✓ DATABASE_URL is set
✓ Can connect to database
✓ Migrations are up to date (Prisma, Drizzle, Knex)
✓ Required tables exist
✓ Database is writable
✗ Data integrity (need tests)
✗ Query performance (need monitoring)
```

### check-api.sh
```
✓ Health endpoint responds
✓ Discovers all API routes
✓ No 500 errors on GET
✓ Auth endpoints return 401 without token
✗ POST/PUT/DELETE logic (need tests)
✗ Rate limiting works (need load tests)
```

### check-integrations.sh
```
✓ Stripe API key valid
✓ Stripe can reach API
✓ Email service (Resend/SendGrid) reachable
✓ AI service (Anthropic/OpenAI) reachable
✓ Database connectable
✓ Redis/cache connectable
✓ Auth provider configured
✗ Webhooks actually work (need integration tests)
✗ Email actually delivers (need monitoring)
```

## What's NOT Covered (Remaining Gaps)

### Need Integration Tests
- [ ] User can actually sign up
- [ ] User can actually log in
- [ ] Payment flow completes
- [ ] Email is received
- [ ] Webhook processes correctly

### Need E2E Tests
- [ ] Full user journeys work
- [ ] Multi-step forms complete
- [ ] Real browser interaction

### Need Monitoring (Post-Deploy)
- [ ] Error rates stay low
- [ ] Response times stay fast
- [ ] No memory leaks
- [ ] Queue jobs complete

### Need Manual Verification
- [ ] UI looks correct
- [ ] Mobile responsive
- [ ] Accessibility (screen reader)
- [ ] Copy/content is right

## How to Close Remaining Gaps

### 1. Add Integration Tests
```typescript
// tests/integration/auth.test.ts
test('user can sign up and log in', async () => {
  // Create user
  const res = await fetch('/api/auth/signup', {
    method: 'POST',
    body: JSON.stringify({ email: 'test@test.com', password: 'password' })
  })
  expect(res.status).toBe(201)

  // Log in
  const loginRes = await fetch('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email: 'test@test.com', password: 'password' })
  })
  expect(loginRes.status).toBe(200)
})
```

### 2. Add E2E Tests
```typescript
// tests/e2e/checkout.spec.ts
test('complete checkout flow', async ({ page }) => {
  await page.goto('/products')
  await page.click('[data-testid="add-to-cart"]')
  await page.click('[data-testid="checkout"]')
  await page.fill('[name="card"]', '4242424242424242')
  await page.click('[data-testid="pay"]')
  await expect(page).toHaveURL(/\/confirmation/)
})
```

### 3. Add Monitoring
```yaml
# Set up alerts for:
- Error rate > 1%
- P99 latency > 500ms
- Failed jobs > 10/hour
- Memory > 80%
```

## Running All Checks

```bash
# Run everything
./scripts/verify-all.sh

# Run specific checks
./scripts/check-wiring.sh
./scripts/check-database.sh
./scripts/check-api.sh
./scripts/check-integrations.sh
```

## CI Integration

```yaml
# .github/workflows/verify.yml
jobs:
  verify:
    steps:
      - run: ./scripts/verify-all.sh
```

This blocks deployment if ANY check fails.
