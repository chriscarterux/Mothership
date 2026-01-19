# Trello Adapter

## Config Required

```json
{
  "state": "trello",
  "trello": {
    "board_id": "your-board-id",
    "lists": {
      "ready": "list-id-for-ready",
      "in_progress": "list-id-for-in-progress",
      "done": "list-id-for-done",
      "blocked": "list-id-for-blocked"
    }
  }
}
```

## Board Setup

Create lists:
- Ready
- In Progress
- Done
- Blocked

## Reading Stories

```bash
# Get cards from Ready list
curl -s "https://api.trello.com/1/lists/$READY_LIST_ID/cards?key=$KEY&token=$TOKEN"
```

## Creating Stories

```bash
curl -s -X POST "https://api.trello.com/1/cards" \
  -d "key=$KEY&token=$TOKEN" \
  -d "idList=$READY_LIST_ID" \
  -d "name=[story title]" \
  -d "desc=[AC and notes]"
```

## Updating Status

Move card to different list:

```bash
curl -s -X PUT "https://api.trello.com/1/cards/$CARD_ID" \
  -d "key=$KEY&token=$TOKEN" \
  -d "idList=$DONE_LIST_ID"
```

## Adding Comments

```bash
curl -s -X POST "https://api.trello.com/1/cards/$CARD_ID/actions/comments" \
  -d "key=$KEY&token=$TOKEN" \
  -d "text=[comment text]"
```

## Status Mapping

| Mothership | Trello List |
|------------|-------------|
| ready | Ready list |
| in_progress | In Progress list |
| done | Done list |
| blocked | Blocked list |
