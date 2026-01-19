# Local JSON Adapter

## File Format

`.mothership/stories.json`:

```json
{
  "project": "Feature Name",
  "branch": "feat/feature-name",
  "stories": [
    {
      "id": "1",
      "title": "User can do X",
      "status": "ready",
      "priority": 1,
      "ac": [
        "Criterion 1",
        "Criterion 2"
      ],
      "files": ["path/to/file.ts"]
    }
  ]
}
```

## Reading Stories

```bash
cat .mothership/stories.json | jq '.stories[] | select(.status == "ready")' | head -1
```

## Creating Stories

Add to the stories array in the JSON file.

## Updating Status

```bash
# Using jq to update status
jq '(.stories[] | select(.id == "1")).status = "done"' \
  .mothership/stories.json > tmp.json && mv tmp.json .mothership/stories.json
```

Or just edit the file directly.

## Adding Comments

Add a `comments` array to the story:

```json
{
  "id": "1",
  "title": "...",
  "comments": [
    {"date": "2024-01-15", "text": "Implementation complete"}
  ]
}
```

## Status Values

| Status | Meaning |
|--------|---------|
| ready | Available for work |
| in_progress | Currently being worked |
| done | Completed |
| blocked | Waiting on something |

## Simplest Option

No external dependencies. Works offline. Good for solo developers.
