# GitHub Issues Adapter

## Reading Stories

```bash
gh issue list --label "mothership" --state open --json number,title,labels,body
```

## Creating Stories

```bash
gh issue create \
  --title "[story title]" \
  --body "[AC and notes]" \
  --label "mothership,ready"
```

## Updating Status

```bash
# Move to in-progress
gh issue edit [NUMBER] --remove-label "ready" --add-label "in-progress"

# Move to done
gh issue edit [NUMBER] --remove-label "in-progress" --add-label "done"
gh issue close [NUMBER]
```

## Adding Comments

```bash
gh issue comment [NUMBER] --body "[comment text]"
```

## Status Mapping (via labels)

| Mothership | GitHub Label |
|------------|--------------|
| ready | ready |
| in_progress | in-progress |
| done | done (+ closed) |
| blocked | blocked |

## Setup

Create labels first:
```bash
gh label create "mothership" --color "6f42c1" --description "Managed by Mothership"
gh label create "ready" --color "0e8a16"
gh label create "in-progress" --color "fbca04"
gh label create "done" --color "1d76db"
gh label create "blocked" --color "d93f0b"
```
