# Trello Adapter

## Setup

### Authentication
```bash
# Get API Key from: https://trello.com/power-ups/admin
# Generate Token from: https://trello.com/1/authorize?expiration=never&scope=read,write&response_type=token&key=YOUR_KEY&name=Mothership

export TRELLO_API_KEY="your_api_key"
export TRELLO_TOKEN="your_token"
```

### Config
In `.mothership/config.json`:
```json
{
  "state": "trello",
  "trello": {
    "board_id": "5FuLgFYU",
    "lists": {
      "ready": "Backlog",
      "in_progress": "Active Request",
      "done": "Approved"
    }
  }
}
```

## Hierarchy Mapping

| Mothership | Trello Entity | Purpose |
|------------|---------------|---------|
| Feature/Epic | **Board** | Groups all project work |
| User story | **Card** | Deliverable unit |
| Acceptance criteria | **Checklist** | Testable tasks |
| Status | **List** | Workflow column |
| Category | **Label** | Service line tag |

## API Commands

### List Cards (Get Ready Stories)
```bash
BOARD_ID="5FuLgFYU"
curl -s "https://api.trello.com/1/boards/${BOARD_ID}/cards?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}&fields=name,desc,idList,labels"
```

### Create Card
```bash
curl -s -X POST "https://api.trello.com/1/cards" \
  --data-urlencode "key=${TRELLO_API_KEY}" \
  --data-urlencode "token=${TRELLO_TOKEN}" \
  --data-urlencode "idList=BACKLOG_LIST_ID" \
  --data-urlencode "name=STORY-ID: Title" \
  --data-urlencode "desc=## Acceptance Criteria\n- [ ] Criterion 1\n- [ ] Criterion 2"
```

### Move Card (Update Status)
```bash
# Move to Active Request (in_progress)
curl -s -X PUT "https://api.trello.com/1/cards/CARD_ID" \
  --data-urlencode "key=${TRELLO_API_KEY}" \
  --data-urlencode "token=${TRELLO_TOKEN}" \
  --data-urlencode "idList=ACTIVE_REQUEST_LIST_ID"

# Move to Approved (done)
curl -s -X PUT "https://api.trello.com/1/cards/CARD_ID" \
  --data-urlencode "key=${TRELLO_API_KEY}" \
  --data-urlencode "token=${TRELLO_TOKEN}" \
  --data-urlencode "idList=APPROVED_LIST_ID"
```

### Add Comment
```bash
curl -s -X POST "https://api.trello.com/1/cards/CARD_ID/actions/comments" \
  --data-urlencode "key=${TRELLO_API_KEY}" \
  --data-urlencode "token=${TRELLO_TOKEN}" \
  --data-urlencode "text=Implementation complete. Tests passing."
```

### Add Checklist (Acceptance Criteria)
```bash
# Create checklist
CHECKLIST_ID=$(curl -s -X POST "https://api.trello.com/1/checklists" \
  --data-urlencode "key=${TRELLO_API_KEY}" \
  --data-urlencode "token=${TRELLO_TOKEN}" \
  --data-urlencode "idCard=CARD_ID" \
  --data-urlencode "name=Acceptance Criteria" | jq -r '.id')

# Add items
curl -s -X POST "https://api.trello.com/1/checklists/${CHECKLIST_ID}/checkItems" \
  --data-urlencode "key=${TRELLO_API_KEY}" \
  --data-urlencode "token=${TRELLO_TOKEN}" \
  --data-urlencode "name=Criterion text here"
```

## Status Mapping

| Mothership | Trello List |
|------------|-------------|
| ready | Backlog |
| in_progress | Active Request |
| done | Approved |

## Label Mapping (Service Lines)

| Service | Trello Label | Color |
|---------|-------------|-------|
| Design | Design | Red |
| Development | Development | Purple |
| AI | AI | Blue |
| Social Media | Social Media | Orange |
| Branding | Branding | Green |
| Marketing | Marketing | Yellow |

## Reading the Next Story

To get the next ready story for `./m build`:
```bash
# Get Backlog list ID
BACKLOG_ID=$(curl -s "https://api.trello.com/1/boards/${BOARD_ID}/lists?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}" | jq -r '.[] | select(.name=="Backlog") | .id')

# Get first card in Backlog
curl -s "https://api.trello.com/1/lists/${BACKLOG_ID}/cards?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}&fields=name,desc" | jq '.[0]'
```
