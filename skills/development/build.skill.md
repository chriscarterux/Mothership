# Skill: Build

Build ONE story from the backlog. Read the state backend, pick up the top card/story, implement, validate, verify by type, commit, update status.

## Context
- Project: Read `.mothership/checkpoint.md`
- Patterns: Read `.mothership/codebase.md`
- State backend: Read `.mothership/config.json` to determine source (trello, linear, or local)

## Steps

### 1. Determine State Backend

Read `.mothership/config.json` and check the `state` field:

```bash
STATE=$(jq -r '.state // "local"' .mothership/config.json 2>/dev/null || echo "local")
```

- `"trello"` → Use Trello API (steps 2a onward)
- `"local"` or missing → Use `.mothership/stories.json` (steps 2b onward)
- `"linear"` → Use Linear API (not covered here)

---

### 1b. Board Confirmation (Trello only, first iteration)

On the first loop iteration when state=trello:

- **If `trello.board_id` exists:** Validate via API, then confirm:
  ```bash
  BOARD_ID=$(jq -r '.trello.board_id' .mothership/config.json)
  BOARD_NAME=$(curl -s "https://api.trello.com/1/boards/${BOARD_ID}?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}&fields=name" | jq -r '.name // empty')
  ```
  - If `BOARD_NAME` is empty (board deleted/invalid) → fall through to "missing" flow
  - Otherwise → brief confirmation: "Building from board [BOARD_NAME] — correct?" (only ask once per session)
- **If missing or invalid:** List boards, let user pick, save to config:
  ```bash
  curl -s "https://api.trello.com/1/members/me/boards?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}&fields=name,url" | jq '.[] | {name, id, url}'
  ```
  Save selection:
  ```bash
  jq --arg id "SELECTED_ID" --arg name "SELECTED_NAME" \
    '.trello.board_id = $id | .trello.board_name = $name' \
    .mothership/config.json > tmp && mv tmp .mothership/config.json
  ```

---

### 2a. Trello: Get Next Story

**Requires:** `TRELLO_API_KEY` and `TRELLO_TOKEN` environment variables.

```bash
# Read board and list config
BOARD_ID=$(jq -r '.trello.board_id' .mothership/config.json)
```

**Get the list IDs from the board:**
```bash
LISTS=$(curl -s "https://api.trello.com/1/boards/${BOARD_ID}/lists?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}")
BACKLOG_ID=$(echo "$LISTS" | jq -r '.[] | select(.name=="Backlog") | .id')
ACTIVE_ID=$(echo "$LISTS" | jq -r '.[] | select(.name=="Active Request") | .id')
APPROVED_ID=$(echo "$LISTS" | jq -r '.[] | select(.name=="Approved") | .id')
```

**Get the top card from Backlog (first card = highest priority):**
```bash
CARD=$(curl -s "https://api.trello.com/1/lists/${BACKLOG_ID}/cards?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}" | jq '.[0]')
CARD_ID=$(echo "$CARD" | jq -r '.id')
CARD_NAME=$(echo "$CARD" | jq -r '.name')
CARD_DESC=$(echo "$CARD" | jq -r '.desc')
```

If no card found (CARD_ID is null) → Output `<mothership>BUILD-COMPLETE</mothership>` → Stop

**Move card to Active Request immediately:**
```bash
curl -s -X PUT "https://api.trello.com/1/cards/${CARD_ID}" \
  --data-urlencode "key=${TRELLO_API_KEY}" \
  --data-urlencode "token=${TRELLO_TOKEN}" \
  --data-urlencode "idList=${ACTIVE_ID}"
```

**Extract story details from card:**
- **Story ID:** Parse from card title (format: `STORY-ID: Title` — everything before the first colon)
- **Acceptance Criteria:** Parse from card description (look for `## Acceptance Criteria` section, checklist items `- [ ]`)
- **Technical Context:** Parse from card description (look for `## Technical Context` section)
- **Testing Requirements:** Parse from card description (look for `## Testing Requirements` section)
- **Files to modify:** Parse from Technical Context section

The card description IS the spec. Read it fully. Build exactly what it says.

→ Continue to Step 3.

---

### 2b. Local: Get Next Story

```bash
STORY=$(jq -r '.stories[] | select(.status=="ready") | .id' .mothership/stories.json | head -1)
STORY_TYPE=$(jq -r ".stories[] | select(.id==\"$STORY\") | .type // \"fullstack\"" .mothership/stories.json)
```
If no story found → Output `<mothership>BUILD-COMPLETE</mothership>` → Stop

Read story requirements:
```bash
jq -r ".stories[] | select(.id==\"$STORY\") | .acceptance_criteria[]" .mothership/stories.json
jq -r ".stories[] | select(.id==\"$STORY\") | .verification.scripts[]?" .mothership/stories.json
jq -r ".stories[] | select(.id==\"$STORY\") | .files[]" .mothership/stories.json
```

→ Continue to Step 3.

---

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
./scripts/check-wiring.sh src/
npm run dev &
sleep 5
curl -s http://localhost:3000/[route] > /dev/null && echo "✓ Renders"
pkill -f "npm run dev"
```

#### If type = "api"
```bash
./scripts/check-api.sh
npm run dev &
sleep 5
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/[endpoint])
[[ "$STATUS" == "200" ]] || [[ "$STATUS" == "401" ]] && echo "✓ Responds"
pkill -f "npm run dev"
```

#### If type = "database"
```bash
./scripts/check-database.sh
npm run db:migrate
npm run db:status
```

#### If type = "integration"
```bash
./scripts/check-integrations.sh
```

#### If type = "fullstack" (or unspecified)
```bash
./scripts/check-wiring.sh src/ || true
./scripts/check-api.sh || true
./scripts/check-database.sh || true
```

### 7. Run Story-Specific Verification Commands

**Trello:** Check the card description for any verification commands listed under `## Testing Requirements`.

**Local:**
```bash
COMMANDS=$(jq -r ".stories[] | select(.id==\"$STORY\") | .verification.commands[]?" .mothership/stories.json)
for cmd in $COMMANDS; do
  echo "Running: $cmd"
  eval "$cmd"
done
```

### 8. Verify Each Acceptance Criterion
For each AC, confirm it is met. If the AC has a verify step, run it.

### 9. Commit
```bash
git add -A
git commit -m "${STORY_ID}: ${STORY_TITLE}"
git push
```

### 10. Update Story Status

**If Trello:**

On SUCCESS — move card to Approved and post completion comment:
```bash
# Move to Approved
curl -s -X PUT "https://api.trello.com/1/cards/${CARD_ID}" \
  --data-urlencode "key=${TRELLO_API_KEY}" \
  --data-urlencode "token=${TRELLO_TOKEN}" \
  --data-urlencode "idList=${APPROVED_ID}"

# Post completion comment
curl -s -X POST "https://api.trello.com/1/cards/${CARD_ID}/actions/comments" \
  --data-urlencode "key=${TRELLO_API_KEY}" \
  --data-urlencode "token=${TRELLO_TOKEN}" \
  --data-urlencode "text=## Completion Report

**Status:** PASSED
**Branch:** $(git branch --show-current)
**Commit:** $(git rev-parse --short HEAD)

### What Was Done
- [list changes made]

### Files Modified
$(git diff --name-only HEAD~1)

### Test Results
- Typecheck: clean
- Lint: clean
- Tests: passed"
```

On FAILURE (after 3 retries) — add failed label and post error comment:
```bash
# Get the "failed" label ID
FAILED_LABEL=$(curl -s "https://api.trello.com/1/boards/${BOARD_ID}/labels?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}" | jq -r '.[] | select(.name=="failed") | .id')

# Add failed label (card stays in Active Request)
curl -s -X POST "https://api.trello.com/1/cards/${CARD_ID}/idLabels" \
  --data-urlencode "key=${TRELLO_API_KEY}" \
  --data-urlencode "token=${TRELLO_TOKEN}" \
  --data-urlencode "value=${FAILED_LABEL}"

# Post failure comment
curl -s -X POST "https://api.trello.com/1/cards/${CARD_ID}/actions/comments" \
  --data-urlencode "key=${TRELLO_API_KEY}" \
  --data-urlencode "token=${TRELLO_TOKEN}" \
  --data-urlencode "text=## Failure Report

**Status:** FAILED
**Error:** ${ERROR_MESSAGE}

### What Failed
- [test/step that failed]

### What Was Attempted
- [approaches tried]

### Suggested Fix
- [root cause if identifiable]"
```

**If Local:**
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
<mothership>BUILT:$STORY_ID</mothership>
```

## On No Stories
```
<mothership>BUILD-COMPLETE</mothership>
```

## On Failure
After 3 failed attempts:
```
<mothership>BLOCKED:$STORY_ID:$REASON</mothership>
```
