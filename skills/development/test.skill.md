# Skill: Test

Write tests for ONE completed story.

## Context
- Read `.mothership/checkpoint.md` for current state
- Find stories with status "done" that need tests

## Steps

### 1. Determine State Backend

Read `.mothership/config.json` and check the `state` field:

```bash
STATE=$(jq -r '.state // "local"' .mothership/config.json 2>/dev/null || echo "local")
```

#### 1a. Trello: Find Story Needing Tests

Fetch cards from the Approved list and find untested cards (no "tested" label):

```bash
BOARD_ID=$(jq -r '.trello.board_id' .mothership/config.json)
LISTS=$(curl -s "https://api.trello.com/1/boards/${BOARD_ID}/lists?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}")
APPROVED_ID=$(echo "$LISTS" | jq -r '.[] | select(.name=="Approved") | .id')

# Get cards from Approved without "tested" label
CARDS=$(curl -s "https://api.trello.com/1/lists/${APPROVED_ID}/cards?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}&fields=name,desc,labels")
CARD=$(echo "$CARDS" | jq '[.[] | select(.labels | map(.name) | index("tested") | not)] | .[0]')
CARD_ID=$(echo "$CARD" | jq -r '.id')
CARD_NAME=$(echo "$CARD" | jq -r '.name')
CARD_DESC=$(echo "$CARD" | jq -r '.desc')
```

If no untested card found → Output `<mothership>TEST-COMPLETE</mothership>` → Stop

Extract story ID from card title and file list from card description.

#### 1b. Local: Find Story Needing Tests

```bash
STORY=$(jq -r '.stories[] | select(.status=="done" and .tested!=true) | .id' .mothership/stories.json | head -1)
```

If no story found → Output `<mothership>TEST-COMPLETE</mothership>` → Stop

### 2. Read Implementation

**Trello:** Parse files from card description's `## Technical Context` section, or use `git log --name-only` to find changed files for the story branch.

**Local:**
```bash
jq -r ".stories[] | select(.id==\"$STORY\") | .files[]" .mothership/stories.json
```

Read each file to understand what to test.

### 3. Write Tests

For each function/component, write tests covering:

**Happy Path**
```typescript
test('does expected thing with valid input', () => {
  expect(myFunction(validInput)).toBe(expectedOutput)
})
```

**Edge Cases**
```typescript
test('handles empty input', () => {
  expect(myFunction('')).toBe(defaultValue)
})

test('handles null', () => {
  expect(myFunction(null)).toThrow()
})
```

**Error Cases**
```typescript
test('throws on invalid input', () => {
  expect(() => myFunction(badInput)).toThrow('Expected error')
})
```

### 4. Run Tests
```bash
npm test -- --testPathPattern="$STORY"
```
If tests fail → Fix → Retry (max 3 times)

### 5. Mark Story as Tested

**Trello:** Add "tested" label to the card. Create the label if it doesn't exist on the board:
```bash
# Look up "tested" label on the board
TESTED_LABEL=$(curl -s "https://api.trello.com/1/boards/${BOARD_ID}/labels?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}" | jq -r '.[] | select(.name=="tested") | .id')

# If label doesn't exist, create it
if [[ -z "$TESTED_LABEL" || "$TESTED_LABEL" == "null" ]]; then
  TESTED_LABEL=$(curl -s -X POST "https://api.trello.com/1/boards/${BOARD_ID}/labels" \
    --data-urlencode "key=${TRELLO_API_KEY}" \
    --data-urlencode "token=${TRELLO_TOKEN}" \
    --data-urlencode "name=tested" \
    --data-urlencode "color=green" | jq -r '.id')
fi

# Apply label to the card
curl -s -X POST "https://api.trello.com/1/cards/${CARD_ID}/idLabels" \
  --data-urlencode "key=${TRELLO_API_KEY}" \
  --data-urlencode "token=${TRELLO_TOKEN}" \
  --data-urlencode "value=${TESTED_LABEL}"
```

**Local:**
```bash
jq "(.stories[] | select(.id==\"$STORY\") | .tested) = true" .mothership/stories.json > tmp && mv tmp .mothership/stories.json
```

### 6. Commit
```bash
git add -A
git commit -m "[$STORY] tests"
```

## Output Signal
```
<mothership>TESTED:$STORY</mothership>
```

## On All Stories Tested
```
<mothership>TEST-COMPLETE</mothership>
```
