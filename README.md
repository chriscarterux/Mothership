# Mothership Core

**The autonomous loop that plans, builds, tests, and reviews.**

```
./mothership.sh plan "user authentication"
./mothership.sh build 20
```

## Quick Start

```bash
# Install
curl -fsSL https://raw.githubusercontent.com/chriscarterux/Mothership---Core/main/install.sh | bash

# Verify setup
./mothership.sh doctor

# Check token usage
./mothership.sh benchmark
```

## What It Does

Mothership Core wraps any AI CLI tool (claude, amp, cursor) in a loop that:

1. **Plans** - Reads your docs, creates stories in Linear or local JSON
2. **Builds** - Implements one story per iteration, commits, continues
3. **Tests** - Writes tests for completed stories
4. **Reviews** - Checks code quality before merge

One story per iteration. Fresh context each time. Loop until done.

## Verify Token Usage

Don't trust claims. Verify:

```bash
$ ./mothership.sh benchmark

  .mothership/mothership.md         898 tokens
  .mothership/checkpoint.md          32 tokens
  .mothership/codebase.md           156 tokens

  TOTAL PER RUN                    1,086 tokens
  Estimated cost/run: $0.003 (Claude Sonnet)
```

See [examples/todo-app/METRICS.md](./examples/todo-app/METRICS.md) for a real project built with Mothership Core.

## Commands

| Command | Description |
|---------|-------------|
| `./mothership.sh plan "feature"` | Create stories from feature description |
| `./mothership.sh build [n]` | Build features (default: 10 iterations) |
| `./mothership.sh test [n]` | Write tests for completed stories |
| `./mothership.sh review` | Review code quality |
| `./mothership.sh benchmark` | Show token counts |
| `./mothership.sh doctor` | Diagnose setup |
| `./mothership.sh trace [mode]` | Show what gets loaded |

## File Structure

```
.mothership/
  mothership.md    # The prompt (required)
  checkpoint.md    # Current state
  codebase.md      # Project patterns
  config.json      # Settings
```

## Optional: Specialized Agents

The default `mothership.md` handles all modes. For teams that want specialization:

```bash
cp agents/*.md .mothership/agents/
```

| Agent | Role |
|-------|------|
| **Cipher** | Planning - creates stories from docs |
| **Vector** | Building - implements stories |
| **Cortex** | Testing - writes tests |
| **Sentinel** | Review - checks quality |

## State Backends

**Default:** Local JSON (`.mothership/stories.json`)

**Linear:** Set in config:
```json
{"state": "linear", "team": "ENG"}
```

See [adapters/state/linear.md](./adapters/state/linear.md) for setup.

## Compared to Ralph

[Ralph](https://github.com/snarktank/ralph) is a loop that builds. Mothership Core is a loop that plans, builds, tests, and reviews.

| | Ralph | Mothership Core |
|---|---|---|
| Core loop | Yes | Yes |
| Fresh context/iteration | Yes | Yes |
| Planning mode | No | Yes |
| Testing mode | No | Yes |
| Review mode | No | Yes |
| Token benchmark cmd | No | Yes |
| Verify with `./mothership.sh benchmark` | - | Yes |

If you just need a build loop, use Ralph. If you want the full workflow, use Mothership Core.

## Credits

Built on ideas from [Geoffrey Huntley](https://ghuntley.com/ralph/) and [Ryan Carson](https://github.com/snarktank/ralph).

## License

MIT
