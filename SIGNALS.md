# Signal Reference

Signals indicate agent completion status. Format: `<agent>SIGNAL:data</agent>`

## Core Agents

| Agent | Signal | Meaning |
|-------|--------|---------|
| cipher | `PLANNED:N` | Planned N stories |
| vector | `BUILT:ID` | Built story ID |
| vector | `BUILD-COMPLETE` | No more stories to build |
| vector | `BLOCKED:ID:R` | Blocked on ID, reason R |
| cortex | `TESTED:ID` | Tested story ID |
| cortex | `TEST-COMPLETE` | All stories tested |
| sentinel | `APPROVED` | Code review passed |
| sentinel | `NEEDS-WORK` | Changes required |

## Default Mode (Single File)

When using the default `mothership.md`, signals use the `<mothership>` tag:

| Signal | Meaning |
|--------|---------|
| `<mothership>PLANNED:N</mothership>` | Planned N stories |
| `<mothership>BUILT:ID</mothership>` | Built story ID |
| `<mothership>BUILD-COMPLETE</mothership>` | No more stories |
| `<mothership>TESTED:ID</mothership>` | Tested story ID |
| `<mothership>TEST-COMPLETE</mothership>` | All tested |
| `<mothership>APPROVED</mothership>` | Review passed |
| `<mothership>NEEDS-WORK</mothership>` | Changes needed |

## Signal Detection

The `mothership.sh` loop detects these signals to determine completion:

```bash
# Build mode completes on:
BUILD-COMPLETE | COMPLETE | B:* | C

# Test mode completes on:
TEST-COMPLETE | COMPLETE | T:*

# Plan mode completes on:
PLANNED | P:*

# Review mode completes on:
APPROVED | NEEDS-WORK | A | NW
```
