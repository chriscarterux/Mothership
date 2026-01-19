# Claude Adapter

## Claude Desktop (MCP)

In Claude Desktop with MCP filesystem access:

```
Read the file at .mothership/mothership.md and execute the command: build
```

## Claude API

```python
import anthropic

client = anthropic.Anthropic()

with open(".mothership/mothership.md") as f:
    prompt_content = f.read()

message = client.messages.create(
    model="claude-sonnet-4-20250514",
    max_tokens=8096,
    messages=[
        {"role": "user", "content": f"{prompt_content}\n\nRun: build"}
    ]
)
```

## Claude Code (VS Code Extension)

In the Claude Code panel:
```
@workspace Read .mothership/mothership.md and run: build
```

## Loop (API)

```python
while True:
    response = run_mothership("build")
    if "COMPLETE" in response:
        break
```

## Tips

- Claude doesn't have native Linear integration - use the API adapter
- For long tasks, use the API with proper context management
- Claude excels at understanding complex codebases
