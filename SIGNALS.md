# Signal Reference

Signals indicate agent completion status. All signals MUST use the format: `<agent>SIGNAL</agent>`

## Core Agents

| Agent | Signal | Meaning | Loop Action |
|-------|--------|---------|-------------|
| cipher | `PLANNED:N` | Planned N stories | Stop (one-shot) |
| vector | `BUILT:ID` | Built story ID | **Continue** |
| vector | `BUILD-COMPLETE` | No more stories to build | **Stop** |
| vector | `BLOCKED:ID:R` | Blocked on ID, reason R | Stop |
| cortex | `TESTED:ID` | Tested story ID | **Continue** |
| cortex | `TEST-COMPLETE` | All stories tested | **Stop** |
| sentinel | `APPROVED` | Code review passed | Stop (one-shot) |
| sentinel | `NEEDS-WORK` | Changes required | Stop (one-shot) |

## Default Mode (Single File)

When using the default `mothership.md`, signals use the `<mothership>` tag:

| Signal | Meaning | Loop Action |
|--------|---------|-------------|
| `<mothership>PLANNED:N</mothership>` | Planned N stories | Stop (one-shot) |
| `<mothership>BUILT:ID</mothership>` | Built story ID | **Continue** to next story |
| `<mothership>BUILD-COMPLETE</mothership>` | No more stories | **Stop** the loop |
| `<mothership>TESTED:ID</mothership>` | Tested story ID | **Continue** to next story |
| `<mothership>TEST-COMPLETE</mothership>` | All tested | **Stop** the loop |
| `<mothership>APPROVED</mothership>` | Review passed | Stop (one-shot) |
| `<mothership>NEEDS-WORK</mothership>` | Changes needed | Stop (one-shot) |

## Signal Detection

The `mothership.sh` loop detects signals in the `<agent>SIGNAL</agent>` format:

```bash
# Build mode stops loop on:
BUILD-COMPLETE

# Test mode stops loop on:
TEST-COMPLETE

# Plan mode stops loop on:
PLANNED:[0-9]+ (one iteration max)

# Review mode stops loop on:
APPROVED | NEEDS-WORK (one iteration max)
```

**Important:**
- `BUILT:ID` signals a story is complete but the loop **continues** to the next story
- `BUILD-COMPLETE` signals there are no more stories, so the loop **stops**
- Same pattern applies for `TESTED:ID` vs `TEST-COMPLETE`
