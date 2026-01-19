# 🛸 5-Minute Quickstart

Get your AI fleet operational in 5 minutes or less.

---

## Prerequisites

Before initiating contact, ensure you have:

- **AI Assistant** — Claude, GPT, or similar LLM
- **Linear Account** — With API access enabled
- **Git Repository** — Your project under version control
- **Node.js Project** — Or similar with linting/testing commands

---

## Step 1: Install (30 seconds)

```bash
cd your-project
/path/to/mothership/install.sh
```

This beams down the `.mothership/` folder into your repo.

---

## Step 2: Configure (1 minute)

Edit `.mothership/config.json`:

```json
{
  "linear_team": "YOUR-TEAM-KEY",
  "quality_commands": {
    "lint": "npm run lint",
    "typecheck": "npm run typecheck",
    "test": "npm test"
  }
}
```

- Set `linear_team` to your Linear team identifier
- Verify `quality_commands` match your project's scripts

---

## Step 3: Add Documentation (2 minutes)

```bash
mkdir -p docs
```

Create feature descriptions the Oracle can interpret:

```markdown
# Feature: User Authentication

Users should be able to log in with email/password.
Sessions expire after 24 hours.
Failed attempts are rate-limited.
```

> 📡 Add your feature documentation to help the Oracle understand what to build.

---

## Step 4: First Build (2 minutes)

Transmit to your AI assistant:

```
Read .mothership/mothership.md and run: build user-authentication
```

The Oracle will:
1. Analyze your docs
2. Create a Linear project
3. Generate implementation stories

---

## Step 5: Continue the Work

After context loss or a break, resume with:

```
Read .mothership/mothership.md and run: continue
```

The fleet picks up exactly where it left off.

---

## Common Commands

| Command | What It Does |
|---------|--------------|
| `build [feature]` | Create Linear project from docs |
| `continue` | Resume current mission |
| `status` | Check fleet progress |
| `review` | Trigger Overseer code review |
| `deploy` | Activate Beacon for deployment |

---

## What to Expect

The fleet operates in formation:

1. **Oracle** — Creates Linear project with prioritized stories
2. **Drone** — Implements one story at a time, commits clean code
3. **Probe** — Writes chaos tests to stress the implementation
4. **Overseer** — Reviews code, requests changes if needed
5. **Beacon** — Deploys when all systems are go (if enabled)

---

## Tips for Success

- 📝 **Write detailed docs** — The Oracle is only as smart as your specs
- 🧩 **Keep stories small** — Atomic units = fewer merge conflicts
- 🔄 **Use "continue" liberally** — Context windows are finite, the fleet remembers
- 📊 **Check Linear** — Your source of truth for mission progress

---

*Welcome aboard, Earth developer. The fleet awaits your commands.* 👽
