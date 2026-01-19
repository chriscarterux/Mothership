# OpenAI Adapter

## ChatGPT (with Code Interpreter)

Upload `.mothership/mothership.md` then:
```
Read the uploaded file and execute: build
```

## OpenAI API

```python
from openai import OpenAI

client = OpenAI()

with open(".mothership/mothership.md") as f:
    prompt_content = f.read()

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "system", "content": prompt_content},
        {"role": "user", "content": "Run: build"}
    ]
)
```

## With Function Calling

```python
tools = [
    {
        "type": "function",
        "function": {
            "name": "execute_command",
            "description": "Execute a shell command",
            "parameters": {
                "type": "object",
                "properties": {
                    "command": {"type": "string"}
                }
            }
        }
    }
]

# Then handle tool calls to actually run commands
```

## Codex CLI (if using)

```bash
codex "Read .mothership/mothership.md and run: build"
```

## Tips

- GPT-4o works well for code generation
- Use function calling for command execution
- Consider Assistants API for stateful conversations
- For file operations, use Code Interpreter or local execution
