# AI Tool Adapters

Mothership works with **any AI coding assistant** that can:
1. Accept a text prompt
2. Execute code/commands
3. Output text (including signals)

## Supported Tools

| Tool | Status | Notes |
|------|--------|-------|
| **Claude Code** | ✅ Primary | Full slash command support |
| **Gemini** | ✅ Primary | Google Gemini CLI |
| **Codex** | ✅ Primary | OpenAI Codex CLI |
| **OpenCode** | ✅ Primary | OpenCode CLI |

## Usage

### Auto-detect (Recommended)
```bash
./mothership.sh build 20
```
Mothership will auto-detect the first available AI tool in order: claude → gemini → codex → opencode

### Specify Tool
```bash
AI_TOOL=gemini ./mothership.sh build 20
AI_TOOL=claude ./mothership.sh plan "user auth"
AI_TOOL=codex ./mothership.sh test
AI_TOOL=opencode ./mothership.sh review
```

### Custom Tool
```bash
CUSTOM_AI_CMD=my-ai-cli \
CUSTOM_PROMPT_FLAG=--prompt \
AI_TOOL=custom \
./mothership.sh build 20
```

## Tool-Specific Setup

### Claude Code
```bash
# Install
npm install -g @anthropic-ai/claude-code

# Prompts location
.claude/commands/mothership-*.md

# Usage
claude "Read .mothership/mothership.md and run: build"
# Or use slash commands:
/mothership:build
```

### Gemini
```bash
# Install Google Cloud CLI with Gemini
gcloud components install gemini

# Usage
AI_TOOL=gemini ./mothership.sh build
```

### Codex (OpenAI)
```bash
# Install OpenAI CLI
pip install openai

# Usage
AI_TOOL=codex ./mothership.sh build
```

### OpenCode
```bash
# Install
# See https://opencode.ai for installation

# Usage
AI_TOOL=opencode ./mothership.sh build
```

## Adding a New AI Tool

### 1. Add to adapter.sh

Edit `adapters/ai/adapter.sh` and add your tool to the `AI_TOOLS` array:

```bash
declare -A AI_TOOLS=(
    # ... existing tools ...
    ["mytool"]="mytool-cli|--prompt|--file|My Custom AI Tool"
)
```

Format: `"command|prompt_flag|file_flag|description"`

### 2. Add Invocation Logic (if special)

If your tool has a unique invocation pattern, add a case in `invoke_ai()`:

```bash
case "$tool" in
    mytool)
        $cmd --special-flag "$prompt"
        ;;
esac
```

### 3. Update mothership.sh

Add detection in the elif chain:
```bash
elif command -v mytool &> /dev/null; then
    AI_CMD="mytool"
```

## Prompts Are AI-Agnostic

The prompts in `.mothership/mothership.md` and `.claude/commands/` are plain markdown. They work with any AI that can:

1. Read the prompt
2. Follow instructions
3. Output signals like `<mothership>BUILT:ID</mothership>`

### For Non-Claude Tools

Copy the prompt content and pass it to your AI:

```bash
# Gemini
gemini --prompt "$(cat .mothership/mothership.md) Run: build"

# Codex
codex --prompt "$(cat .mothership/mothership.md) Run: build"

# OpenCode
opencode --prompt "$(cat .mothership/mothership.md) Run: build"
```

## Signal Format

All AI tools must output signals in the format:
```
<agent>SIGNAL</agent>
```

Examples:
```
<mothership>BUILT:STORY-001</mothership>
<mothership>BUILD-COMPLETE</mothership>
<mothership>VERIFIED:STORY-001</mothership>
```

The `mothership.sh` loop detects these signals using regex - works regardless of which AI produces the output.
