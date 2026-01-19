# Generic AI Adapter

Works with any LLM that can read files and follow instructions.

## Basic Invocation

Provide the LLM with:
1. Contents of `.mothership/mothership.md`
2. Command to execute

```
[Paste contents of .mothership/mothership.md]

---

Execute the following command: build
```

## Requirements

Your AI tool needs to be able to:
- Read files from the filesystem
- Execute shell commands (or you execute them manually)
- Write/edit files

## Manual Mode

If your AI can't execute commands directly:

1. AI reads mothership.md and tells you what to do
2. You run the commands
3. You paste the output back
4. AI continues

Example:
```
AI: "I need to run: git status"
You: [run it, paste output]
AI: "Now I'll create the file..."
You: [copy the file content AI provides]
```

## Wrapper Script

For any LLM with an API:

```bash
#!/bin/bash
PROMPT=$(cat .mothership/mothership.md)
COMMAND="Run: $1"

# Call your LLM API
curl -X POST "your-llm-api" \
  -d "{\"prompt\": \"$PROMPT\n\n$COMMAND\"}"
```

## Tips

- The prompts are tool-agnostic
- State adapters work with any LLM
- Main requirement: ability to read/write files and run commands
