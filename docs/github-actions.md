# Mothership GitHub Action

Use Mothership's AI agents directly in your GitHub workflows.

## Quick Start

```yaml
- uses: chriscarterux/Mothership@main
  with:
    mode: build
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `mode` | Mode to run: `plan`, `build`, `test`, `review` | Yes | `build` |
| `max-iterations` | Maximum iterations for loop modes | No | `10` |
| `ai-tool` | AI CLI tool to use (`amp`, `claude`, `aider`, `auto`) | No | `auto` |

## Modes

- **plan** - Generate implementation plans from requirements
- **build** - Build features with AI-powered code generation
- **test** - Run tests and fix failures iteratively
- **review** - Review code and suggest improvements

## Examples

### Build a Feature

```yaml
name: Build Feature
on:
  workflow_dispatch:
    inputs:
      feature:
        description: 'Feature to build'
        required: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: chriscarterux/Mothership@main
        with:
          mode: build
          max-iterations: 20
```

### Test and Fix Loop

```yaml
name: Test Loop
on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: chriscarterux/Mothership@main
        with:
          mode: test
          max-iterations: 5
```

### Code Review

```yaml
name: AI Review
on: [pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: chriscarterux/Mothership@main
        with:
          mode: review
```

## Environment Variables

Set these in your repository secrets or workflow:

- `ANTHROPIC_API_KEY` - For Claude CLI
- `OPENAI_API_KEY` - For other AI tools

## Notes

- The action auto-downloads `mothership.sh` if not present in your repo
- Use `ai-tool: auto` to let Mothership detect available AI tools
- Increase `max-iterations` for complex features
