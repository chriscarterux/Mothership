# Skill: Plan

Create atomic user stories from a feature description. Every story MUST include verification requirements.

## Input
- Feature description (from user or docs/)

## Context
- Read `.mothership/codebase.md` for project patterns
- Read existing stories in `.mothership/stories.json`

## Steps

### 1. Analyze Feature
Break down the feature into small, independent pieces:
- Each story = ONE component, route, or function
- Should take ~15-20 minutes to implement
- No dependencies within stories if possible

### 2. Identify Story Type
For each piece, determine its type:
- **UI** = Component, page, form
- **API** = Endpoint, route handler
- **Database** = Migration, schema change
- **Integration** = Third-party service connection
- **Full-stack** = UI + API + Database together

### 3. Create Stories with Required Verification

Every story MUST include type-specific verification:

#### UI Stories MUST include:
```yaml
acceptance_criteria:
  - "Component renders without error"
  - "onClick handler calls [specific function]"
    verify: "Click button, see network request in DevTools"
  - "Form submits data to /api/[endpoint]"
    verify: "Submit form, see POST request with correct payload"
  - "Error state shows when [condition]"
    verify: "Trigger error, see error message appear"

verification:
  script: "check-wiring.sh"
  manual:
    - "Component visible at /[route]"
    - "Keyboard navigation works"
```

#### API Stories MUST include:
```yaml
acceptance_criteria:
  - "GET /api/[route] returns 200 with [shape]"
    verify: "curl /api/[route] returns expected JSON"
  - "POST /api/[route] validates input"
    verify: "curl with bad data returns 400"
  - "Endpoint requires authentication"
    verify: "curl without token returns 401"

verification:
  script: "check-api.sh"
  commands:
    - "curl -s http://localhost:3000/api/[route] | jq ."
```

#### Database Stories MUST include:
```yaml
acceptance_criteria:
  - "Migration creates [table] with columns [list]"
    verify: "psql -c '\\d [table]' shows schema"
  - "Migration is reversible"
    verify: "npm run db:rollback succeeds"
  - "[Table] has required indexes"
    verify: "psql -c '\\di' shows index"

verification:
  script: "check-database.sh"
  commands:
    - "npm run db:migrate"
    - "npm run db:status"
```

#### Integration Stories MUST include:
```yaml
acceptance_criteria:
  - "[Service] API key is configured"
    verify: "check-env.sh passes"
  - "[Service] responds to test request"
    verify: "curl [service]/health returns 200"
  - "Webhook endpoint handles [event]"
    verify: "Send test webhook, see log output"

verification:
  script: "check-integrations.sh"
```

#### Full-Stack Stories MUST include:
```yaml
acceptance_criteria:
  # UI criteria
  - "Form renders at /[route]"
  - "Submit button calls API"
  # API criteria
  - "POST /api/[route] saves to database"
  - "Returns created resource"
  # Database criteria
  - "Data persists in [table]"

verification:
  scripts:
    - "check-wiring.sh"
    - "check-api.sh"
    - "check-database.sh"
  e2e_test: "User can complete [flow] from start to finish"
```

### 4. Story Template

```json
{
  "id": "FEATURE-001",
  "title": "User can [verb] [noun]",
  "type": "ui|api|database|integration|fullstack",
  "status": "ready",
  "acceptance_criteria": [
    {
      "criterion": "Specific testable statement",
      "verify": "How to verify this works"
    }
  ],
  "files": ["expected/file/paths.ts"],
  "verification": {
    "scripts": ["check-wiring.sh"],
    "commands": ["curl http://localhost:3000/api/health"],
    "e2e": "Description of end-to-end test needed"
  },
  "test_requirements": {
    "unit": ["functions to test"],
    "integration": ["flows to test"],
    "e2e": ["user journeys to test"]
  }
}
```

### 5. Generate Verification Stories

After creating feature stories, ALSO create verification stories:

```json
{
  "id": "VERIFY-001",
  "title": "Verify [feature] database tables exist",
  "type": "verification",
  "acceptance_criteria": [
    {"criterion": "Table [name] exists", "verify": "psql -c '\\dt'"},
    {"criterion": "All columns present", "verify": "psql -c '\\d [table]'"},
    {"criterion": "Indexes created", "verify": "psql -c '\\di'"}
  ],
  "verification": {
    "scripts": ["check-database.sh"]
  }
}
```

```json
{
  "id": "VERIFY-002",
  "title": "Verify [feature] API endpoints respond",
  "type": "verification",
  "acceptance_criteria": [
    {"criterion": "GET /api/[x] returns 200", "verify": "curl test"},
    {"criterion": "POST /api/[x] validates input", "verify": "curl with bad data"},
    {"criterion": "Auth required on protected routes", "verify": "curl without token"}
  ],
  "verification": {
    "scripts": ["check-api.sh"]
  }
}
```

### 6. Save Stories
```bash
jq '.stories += [NEW_STORIES]' .mothership/stories.json > tmp && mv tmp .mothership/stories.json
```

### 7. Update Checkpoint
```bash
cat > .mothership/checkpoint.md << EOF
phase: build
project: [Feature Name]
branch: feat/[feature-name]
story: null
EOF
```

## Output

List of stories created, grouped by type:

```
Created 12 stories:

Feature Stories:
- FEATURE-001: User can view dashboard (ui)
- FEATURE-002: User can update profile (fullstack)
- FEATURE-003: Create user preferences table (database)
- FEATURE-004: Connect Stripe for payments (integration)

Verification Stories:
- VERIFY-001: Verify dashboard API endpoints
- VERIFY-002: Verify user preferences table
- VERIFY-003: Verify Stripe integration works
```

## Output Signal
```
<mothership>PLANNED:[count]</mothership>
```

Example: `<mothership>PLANNED:12</mothership>` (created 12 stories including verification)
