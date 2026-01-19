# 🛸 ASSIMILATE

> *"Initiating neural link... Scanning host environment..."*

You are integrating Mothership into a project. Follow this protocol.

---

## PHASE 1: SCAN

Detect the host environment automatically:

```bash
# Project type
ls package.json 2>/dev/null && echo "DETECTED: Node.js"
ls Cargo.toml 2>/dev/null && echo "DETECTED: Rust"
ls go.mod 2>/dev/null && echo "DETECTED: Go"
ls requirements.txt pyproject.toml 2>/dev/null && echo "DETECTED: Python"

# Existing state systems
ls .linear 2>/dev/null && echo "DETECTED: Linear"
ls .jira 2>/dev/null && echo "DETECTED: Jira"
ls .github/ISSUE_TEMPLATE 2>/dev/null && echo "DETECTED: GitHub Issues"

# Existing AI tools
ls .amp 2>/dev/null && echo "DETECTED: Amp"
ls .claude 2>/dev/null && echo "DETECTED: Claude"
ls .cursor 2>/dev/null && echo "DETECTED: Cursor"

# Repo state
ls -la | wc -l | xargs -I {} sh -c '[ {} -lt 5 ] && echo "DETECTED: Empty repo" || echo "DETECTED: Existing codebase"'
```

Report findings to the human:

```
🛸 SCAN COMPLETE

Environment:
- Project: [detected or "Unknown"]
- State system: [detected or "None found"]
- AI tool: [detected or "None found"]
- Repo: [Empty / Existing codebase]
```

---

## PHASE 2: QUERY

Ask ONLY what wasn't detected. Use this exact format:

```
🛸 CONFIGURATION REQUIRED

I detected [X]. I need to know:

1. STATE BACKEND - Where should I track stories?
   → linear (recommended for teams)
   → jira (enterprise)
   → github (GitHub Issues)
   → json (local file, simplest)
   → notion
   → trello

2. AI TOOL - What are you using?
   → amp (Amp by Sourcegraph)
   → claude (Claude Code / Claude Desktop)
   → cursor (Cursor IDE)
   → openai (ChatGPT / Codex)
   → other (generic, works anywhere)

3. VERSION - How much power do you need?
   → lite (one file, ~200 lines, simple)
   → full (specialized agents, more control)

4. DOCS LOCATION - Where are your feature docs?
   → ./docs (default)
   → [custom path]

Reply with your choices, e.g.: "linear, amp, full, ./docs"
```

---

## PHASE 3: CONFIGURE

Based on answers, generate the setup:

### Create .mothership/

```bash
mkdir -p .mothership/agents
```

### Generate config.json

```javascript
// Adapt based on state backend choice:

// LINEAR
{
  "state": "linear",
  "linear": { "team": "ASK_USER" },
  "ai_tool": "[CHOSEN]",
  "docs_path": "[CHOSEN]",
  "commands": { /* detect from package.json/Cargo.toml/etc */ }
}

// JIRA  
{
  "state": "jira",
  "jira": { "project": "ASK_USER", "base_url": "ASK_USER" },
  ...
}

// GITHUB
{
  "state": "github",
  "github": { "repo": "DETECT_FROM_GIT" },
  ...
}

// JSON (simplest)
{
  "state": "json",
  "json": { "file": "stories.json" },
  ...
}

// NOTION
{
  "state": "notion",
  "notion": { "database_id": "ASK_USER" },
  ...
}

// TRELLO
{
  "state": "trello", 
  "trello": { "board_id": "ASK_USER" },
  ...
}
```

### Generate AI-tool specific prompts

**For Amp:**
```markdown
# Invocation
echo "Read .mothership/mothership.md and run: [command]" | amp

# Loop
./mothership.sh build 20
```

**For Claude Code:**
```markdown
# Invocation (in Claude Desktop or API)
Read the file .mothership/mothership.md and execute: [command]

# Note: Claude Code doesn't have a CLI loop - run manually or use API
```

**For Cursor:**
```markdown
# Invocation (in Cursor chat)
@file .mothership/mothership.md - run: [command]

# Or use Cursor's composer mode
```

**For OpenAI/Generic:**
```markdown
# Invocation
Read .mothership/mothership.md and follow the instructions for: [command]

# Works with any LLM that can read files and execute commands
```

### Copy appropriate version

```bash
# If lite chosen:
cp [mothership-repo]/lite/mothership.md .mothership/

# If full chosen:
cp [mothership-repo]/full/mothership.md .mothership/
cp [mothership-repo]/full/agents/*.md .mothership/agents/
```

### Adapt prompts for AI tool

Replace invocation examples in copied prompts based on ai_tool choice.

---

## PHASE 4: ONBOARD

If existing codebase detected, run onboarding:

```
🛸 ASSIMILATING CODEBASE PATTERNS...
```

```bash
# Scan structure
tree -L 2 -I 'node_modules|.git|dist|target|__pycache__' 2>/dev/null | head -30

# Detect patterns
cat package.json 2>/dev/null | head -20  # Node
cat Cargo.toml 2>/dev/null | head -20    # Rust
cat go.mod 2>/dev/null | head -10        # Go
cat pyproject.toml 2>/dev/null | head -20 # Python

# Find existing conventions
ls -la src/ app/ lib/ 2>/dev/null | head -10
```

Generate `.mothership/codebase.md`:

```markdown
# Codebase Patterns
Assimilated: [timestamp]

## Stack
- Language: [detected]
- Framework: [detected]
- Package manager: [detected]

## Structure
- Source: [path]
- Components: [path]
- Tests: [path]

## Commands
- Build: [detected]
- Test: [detected]
- Lint: [detected]

## Patterns
- [Reference to good example file]
```

---

## PHASE 5: VERIFY

Show the human what was created:

```
🛸 ASSIMILATION COMPLETE

Created:
├── .mothership/
│   ├── mothership.md      # [lite/full] version
│   ├── config.json        # [state backend] configured
│   ├── codebase.md        # Patterns assimilated
│   └── agents/            # (if full version)

Configuration:
- State: [chosen] 
- AI Tool: [chosen]
- Docs: [path]

FIRST COMMAND:
[AI-tool specific invocation for: plan your-first-feature]

The Mothership awaits your command. 🛸
```

---

## QUICK RESPONSES

If human says just "integrate mothership" with no details:
→ Run full SCAN, then QUERY for missing info

If human provides all info upfront:
→ Skip QUERY, go straight to CONFIGURE

If human says "just use defaults":
→ Use: json, other, lite, ./docs

If human says "I use [specific tool]":
→ Detect tool, ask only remaining questions

---

## EXAMPLE INTERACTION

**Human:** Integrate this Mothership repo into my project

**AI:** 
```
🛸 SCAN COMPLETE

Environment:
- Project: Next.js (detected package.json)
- State system: None found
- AI tool: Amp (detected .amp/)
- Repo: Existing codebase (47 files)

🛸 CONFIGURATION REQUIRED

I detected Next.js + Amp. I need to know:

1. STATE BACKEND: linear, jira, github, json, notion, trello?
2. VERSION: lite or full?
3. DOCS LOCATION: ./docs or custom path?

Reply with choices, e.g.: "linear, full, ./docs"
```

**Human:** json, lite, ./features

**AI:**
```
🛸 CONFIGURING...

[Creates .mothership/ with lite version, json backend, ./features as docs path]

🛸 ASSIMILATION COMPLETE

Created:
├── .mothership/
│   ├── mothership.md      # lite version (214 lines)
│   ├── config.json        # json backend
│   └── codebase.md        # Next.js patterns assimilated

FIRST COMMAND:
echo "Read .mothership/mothership.md and run: plan your-feature" | amp

The Mothership awaits. 🛸
```

---

*"Your project has been assimilated. Resistance was unnecessary."* 🛸
