# Jira Adapter

## Config Required

```json
{
  "state": "jira",
  "jira": {
    "base_url": "https://yourcompany.atlassian.net",
    "project": "PROJ"
  }
}
```

## Reading Stories

```bash
# Using Jira CLI or API
jira issue list --project "[PROJECT]" --status "To Do" --type "Story"

# Or via curl
curl -s -u "$JIRA_EMAIL:$JIRA_TOKEN" \
  "$JIRA_URL/rest/api/3/search?jql=project=[PROJECT]+AND+status='To Do'"
```

## Creating Stories

```bash
jira issue create \
  --project "[PROJECT]" \
  --type "Story" \
  --summary "[story title]" \
  --description "[AC and notes]"
```

## Updating Status

```bash
jira issue transition [ISSUE-KEY] "In Progress"
jira issue transition [ISSUE-KEY] "Done"
```

## Adding Comments

```bash
jira issue comment add [ISSUE-KEY] "[comment text]"
```

## Status Mapping

| Mothership | Jira (typical) |
|------------|----------------|
| ready | To Do |
| in_progress | In Progress |
| done | Done |
| blocked | Blocked |

Note: Jira workflows vary. Adjust mapping in config if needed.
