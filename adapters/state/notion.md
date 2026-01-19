# Notion Adapter

## Config Required

```json
{
  "state": "notion",
  "notion": {
    "database_id": "your-database-id"
  }
}
```

## Database Setup

Create a Notion database with columns:
- Title (title)
- Status (select: Ready, In Progress, Done, Blocked)
- Priority (number: 1-4)
- AC (text)
- Files (text)

## Reading Stories

```bash
# Via Notion API
curl -s -X POST "https://api.notion.com/v1/databases/$DATABASE_ID/query" \
  -H "Authorization: Bearer $NOTION_TOKEN" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{"filter": {"property": "Status", "select": {"equals": "Ready"}}}'
```

## Creating Stories

```bash
curl -s -X POST "https://api.notion.com/v1/pages" \
  -H "Authorization: Bearer $NOTION_TOKEN" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{
    "parent": {"database_id": "'$DATABASE_ID'"},
    "properties": {
      "Title": {"title": [{"text": {"content": "[story title]"}}]},
      "Status": {"select": {"name": "Ready"}},
      "Priority": {"number": 1}
    }
  }'
```

## Updating Status

```bash
curl -s -X PATCH "https://api.notion.com/v1/pages/$PAGE_ID" \
  -H "Authorization: Bearer $NOTION_TOKEN" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{"properties": {"Status": {"select": {"name": "Done"}}}}'
```

## Status Mapping

| Mothership | Notion Select |
|------------|---------------|
| ready | Ready |
| in_progress | In Progress |
| done | Done |
| blocked | Blocked |
