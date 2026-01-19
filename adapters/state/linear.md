# Linear Adapter

## Reading Stories

```
Linear:list_issues
  project: "[project name]"
  state: "Ready"
  limit: 10
```

## Creating Stories

```
Linear:create_issue
  team: "[team from config]"
  project: "[project name]"
  title: "[story title]"
  description: "[AC and notes]"
  state: "Ready"
  priority: [1-4]
```

## Updating Status

```
Linear:update_issue
  id: "[ISSUE-ID]"
  state: "[Ready|In Progress|Done|Blocked]"
```

## Adding Comments

```
Linear:create_comment
  issueId: "[ISSUE-ID]"
  body: "[comment text]"
```

## Status Mapping

| Mothership | Linear |
|------------|--------|
| ready | Ready |
| in_progress | In Progress |
| done | Done |
| blocked | Blocked |
