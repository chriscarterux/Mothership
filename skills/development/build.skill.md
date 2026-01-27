# Skill: Build

Build ONE story from the backlog. Implement, validate, verify by type, commit.

## Context
- Project: Read `.mothership/checkpoint.md`
- Patterns: Read `.mothership/codebase.md`
- Stories: Read `.mothership/stories.json`

## Steps

### 1. Get Next Story
```bash
STORY=$(jq -r '.stories[] | select(.status=="ready") | .id' .mothership/stories.json | head -1)
STORY_TYPE=$(jq -r ".stories[] | select(.id==\"$STORY\") | .type // \"fullstack\"" .mothership/stories.json)
```
If no story found → Output `<mothership>BUILD-COMPLETE</mothership>` → Stop

### 2. Read Story Requirements
```bash
# Acceptance criteria
jq -r ".stories[] | select(.id==\"$STORY\") | .acceptance_criteria[]" .mothership/stories.json

# Verification scripts to run
jq -r ".stories[] | select(.id==\"$STORY\") | .verification.scripts[]?" .mothership/stories.json

# Expected files
jq -r ".stories[] | select(.id==\"$STORY\") | .files[]" .mothership/stories.json
```

### 3. Find Similar Code
Search codebase for similar patterns. Copy the style.

### 4. Implement
- One file at a time
- Type-check after each file: `npm run typecheck`
- Follow acceptance criteria exactly

### 5. Run Standard Validation
```bash
npm run typecheck
npm run lint
npm test
```
If any fails → Fix → Retry (max 3 times)

### 6. Run Type-Specific Verification

#### If type = "ui"
```bash
# Check for empty handlers
./scripts/check-wiring.sh src/

# Verify component renders
npm run dev &
sleep 5
curl -s http://localhost:3000/[route] > /dev/null && echo "✓ Renders"
pkill -f "npm run dev"
```

#### If type = "api"
```bash
# Check API endpoints
./scripts/check-api.sh

# Test specific endpoint
npm run dev &
sleep 5
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/[endpoint])
[[ "$STATUS" == "200" ]] || [[ "$STATUS" == "401" ]] && echo "✓ Responds"
pkill -f "npm run dev"
```

#### If type = "database"
```bash
# Check database
./scripts/check-database.sh

# Verify migration
npm run db:migrate
npm run db:status
```

#### If type = "integration"
```bash
# Check integrations
./scripts/check-integrations.sh
```

#### If type = "fullstack" (or unspecified)
```bash
# Run ALL checks
./scripts/check-wiring.sh src/ || true
./scripts/check-api.sh || true
./scripts/check-database.sh || true
```

### 7. Run Story-Specific Verification Commands
```bash
# Execute any custom verification commands from story
COMMANDS=$(jq -r ".stories[] | select(.id==\"$STORY\") | .verification.commands[]?" .mothership/stories.json)
for cmd in $COMMANDS; do
  echo "Running: $cmd"
  eval "$cmd"
done
```

### 8. Verify Each Acceptance Criterion
For each AC with a `verify` field, run the verification:
```bash
jq -r ".stories[] | select(.id==\"$STORY\") | .acceptance_criteria[] | select(.verify) | .verify" .mothership/stories.json
```

### 9. Commit
```bash
git add -A
git commit -m "[$STORY] $STORY_TITLE"
git push
```

### 10. Update Story Status
```bash
jq "(.stories[] | select(.id==\"$STORY\") | .status) = \"done\"" .mothership/stories.json > tmp && mv tmp .mothership/stories.json
```

## Verification Checklist

### All Stories
- [ ] `npm run typecheck` passes
- [ ] `npm run lint` passes
- [ ] `npm test` passes

### UI Stories (type: ui)
- [ ] `check-wiring.sh` passes (no empty handlers)
- [ ] Component renders at expected route
- [ ] All AC verification steps pass

### API Stories (type: api)
- [ ] `check-api.sh` passes (no 500s)
- [ ] Endpoint returns expected status
- [ ] Response shape matches AC

### Database Stories (type: database)
- [ ] `check-database.sh` passes
- [ ] Migration runs
- [ ] Table/columns exist

### Integration Stories (type: integration)
- [ ] `check-integrations.sh` passes
- [ ] Service responds

### Full-Stack Stories (type: fullstack)
- [ ] ALL checks pass

## Output Signal
```
<mothership>BUILT:$STORY</mothership>
```

## On No Stories
```
<mothership>BUILD-COMPLETE</mothership>
```

## On Failure
After 3 failed attempts:
```
<mothership>BLOCKED:$STORY:$REASON</mothership>
```
