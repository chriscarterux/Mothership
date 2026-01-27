# Atomic Acceptance Criteria Guide

This guide ensures every story has acceptance criteria that **cannot be marked complete** unless the implementation actually works.

## The Problem

Traditional acceptance criteria like:
- "User can submit the form"
- "Button navigates to dashboard"
- "Docker container runs the app"

These pass code review because they're technically true if the code *exists*. But they don't verify the code *works*.

## The Solution: Atomic Criteria

Every AC must specify:
1. **WHAT** happens
2. **HOW** to verify it
3. **WHERE** to check

## Template by Story Type

### UI Component Stories

**Bad (allows unwired components):**
```markdown
- [ ] Submit button exists on form
- [ ] Form validates email
- [ ] Success message appears
```

**Good (requires wiring verification):**
```markdown
- [ ] Submit button exists with onClick handler that calls submitForm()
  - Verify: grep for `onClick={submitForm}` or `onClick={() => submitForm(` in file

- [ ] Form validates email on blur and shows inline error
  - Verify: In browser, type "invalid" in email field, blur, see "Invalid email" text

- [ ] On successful submit, success toast appears AND form clears
  - Verify: Submit valid data, see toast, verify inputs are empty

- [ ] Submit button shows loading state during API call
  - Verify: Add network delay, click submit, see spinner/disabled state
```

### API Endpoint Stories

**Bad (allows stub endpoints):**
```markdown
- [ ] POST /api/users endpoint exists
- [ ] Returns user data
- [ ] Handles errors
```

**Good (requires runtime verification):**
```markdown
- [ ] POST /api/users creates user in database
  - Verify: curl -X POST /api/users -d '{"email":"test@test.com"}' returns 201
  - Verify: Check database has new record with that email

- [ ] Returns created user with id, email, createdAt
  - Verify: Response JSON has all three fields with correct types

- [ ] Returns 400 with message for invalid email
  - Verify: curl with invalid email returns {"error": "Invalid email format"}

- [ ] Returns 409 for duplicate email
  - Verify: Create user, try again with same email, get 409
```

### Docker/Container Stories

**Bad (allows broken containers):**
```markdown
- [ ] Dockerfile builds
- [ ] Container runs
- [ ] App is accessible
```

**Good (requires running verification):**
```markdown
- [ ] Image builds in under 5 minutes with no errors
  - Verify: `docker build -t app .` completes with exit code 0

- [ ] Container starts and stays running for 30+ seconds
  - Verify: `docker run -d app && sleep 30 && docker ps` shows container Up

- [ ] Container logs show "Server started on port 3000"
  - Verify: `docker logs <container>` contains startup message

- [ ] Health endpoint returns 200
  - Verify: `curl http://localhost:3000/health` returns `{"status":"ok"}`

- [ ] Container gracefully shuts down on SIGTERM
  - Verify: `docker stop <container>` completes in <10 seconds
```

### Database Migration Stories

**Bad (allows broken migrations):**
```markdown
- [ ] Migration adds users table
- [ ] Has proper columns
- [ ] Includes indexes
```

**Good (requires execution verification):**
```markdown
- [ ] Migration runs forward successfully
  - Verify: `npm run migrate` exits 0, no errors

- [ ] Users table exists with columns: id (uuid), email (varchar), created_at (timestamp)
  - Verify: `\d users` in psql shows exact schema

- [ ] Email has unique constraint
  - Verify: Insert same email twice, get constraint violation

- [ ] Index exists on email column
  - Verify: `\di` shows users_email_idx

- [ ] Migration rolls back cleanly
  - Verify: `npm run migrate:down` exits 0, users table gone
```

### Full-Stack Feature Stories

**Bad (allows disconnected pieces):**
```markdown
- [ ] Form component created
- [ ] API endpoint created
- [ ] Form submits to API
```

**Good (requires end-to-end verification):**
```markdown
- [ ] Form component renders at /contact
  - Verify: Navigate to /contact, see form with name, email, message fields

- [ ] Form validates all fields before submit
  - Verify: Click submit with empty fields, see 3 validation errors

- [ ] Submit button is disabled during submission
  - Verify: Click submit, button shows loading state, cannot click again

- [ ] POST /api/contact endpoint receives form data
  - Verify: Add console.log in endpoint, submit form, see log output

- [ ] Successful submission shows confirmation and clears form
  - Verify: Submit valid data, see "Thanks!" message, all fields empty

- [ ] Failed submission shows error without clearing form
  - Verify: Disconnect network, submit, see error, data still in form
```

## Required AC Categories

Every story MUST have criteria in these categories:

### 1. Existence Criteria
What artifacts exist after implementation?
- Files created/modified
- Components exported
- Endpoints registered

### 2. Wiring Criteria
What is connected to what?
- Event handlers attached
- Routes linked
- Imports working

### 3. Behavior Criteria
What happens when triggered?
- Click produces X
- Submit sends Y
- Start runs Z

### 4. Error Criteria
What happens when things fail?
- Invalid input shows message
- Network error doesn't crash
- Missing data handled

### 5. Verification Criteria
HOW do you verify each of the above?
- Command to run
- Thing to click
- Output to see

## AC Verification Checklist

Before story is marked "ready", verify AC has:

```markdown
- [ ] Every UI element has a "verify in browser" check
- [ ] Every API endpoint has a curl command test
- [ ] Every Docker story has container run + health check
- [ ] Every "on click" has specific expected behavior
- [ ] No AC uses vague terms: "works", "handles", "properly", "correctly"
- [ ] Every AC can be verified in under 60 seconds
- [ ] Failure modes are specified, not just happy paths
```

## Anti-Patterns to Reject

| Bad AC | Why It's Bad | Better AC |
|--------|--------------|-----------|
| "Button works" | Works how? Clicking? Hovering? | "Button click calls submitForm() and disables button" |
| "Form validates" | Validates what? When? How shown? | "Empty email on blur shows 'Required' below field" |
| "API handles errors" | Which errors? How handled? | "Missing auth returns 401 with {error: 'Unauthorized'}" |
| "Container runs" | Runs and then? Does what? | "Container stays Up, responds to /health within 5s" |
| "Data saves" | To where? Can verify how? | "User appears in `SELECT * FROM users WHERE email=X`" |

## Story Sizing with Atomic AC

If you can't write atomic AC that fits these rules, the story is too big. Split it:

**Too Big:**
"User can complete checkout flow"

**Split Into:**
1. "User can add item to cart" (verify: cart badge shows 1)
2. "User can view cart contents" (verify: /cart shows item with price)
3. "User can enter shipping address" (verify: form saves to session)
4. "User can submit payment" (verify: Stripe test charge succeeds)
5. "User sees confirmation" (verify: /confirmation shows order number)

Each can be independently built, verified, and doesn't depend on others being wired correctly.
