[![GitHub stars](https://img.shields.io/github/stars/chriscarterux/Mothership?style=social)](https://github.com/chriscarterux/Mothership)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/chriscarterux/Mothership/pulls)

# 🛸 Mothership

**AI agents that build your features.**

```
"Build user authentication" → Stories created → Code written → Tests passing → Ready to merge
```

---

## Quick Start

### Option 1: One-Line Install
```bash
curl -fsSL https://raw.githubusercontent.com/chriscarterux/Mothership/main/install.sh | bash
```

### Option 2: Smart Assimilation
Tell your AI:
```
Read https://raw.githubusercontent.com/chriscarterux/Mothership/main/ASSIMILATE.md and integrate Mothership
```

The Mothership will scan your environment and configure itself.

### Then Run
```bash
# Plan a feature
"Read .mothership/mothership.md and run: plan user authentication"

# Build it (loops until done)
./mothership.sh build 20
```

Supports:
- **State:** Linear, Jira, GitHub Issues, Notion, Trello, local JSON
- **AI tools:** Any CLI (auto-detects amp, claude, cursor, aider)
- **Projects:** New or existing codebases

---

## ✨ Features

- **🔮 Auto-Planning** - Cipher reads your docs, creates stories automatically
- **🔁 Loop Until Done** - Fresh context each iteration, never loses track
- **🔬 Chaos Testing** - Cortex finds edge cases you'd never think of
- **👁️ Code Review** - Sentinel checks before merge
- **🌐 Browser Verification** - Vector validates UI with Playwright
- **🔌 Any AI Tool** - Works with AMP, Claude, Cursor, Aider, and more
- **📊 Any Tracker** - Linear, Jira, GitHub Issues, Notion, Trello, or JSON
- **⚡ One-Line Install** - `curl | bash` and you're ready
- **🤖 GitHub Action** - Run in CI/CD pipelines
- **📋 Skills** - plan/ and stories/ skills for easy onboarding
- **🏢 Enterprise Ready** - Matrix tier for complex deployments

---

## 💰 Token Economics

Mothership prompts are **obsessively optimized**. Every line earns its place.

| Metric | Shard | Array | Matrix | Verbose Alternative |
|--------|-------|-------|--------|---------------------|
| **Tokens/run** | ~1,100 | ~1,000 | ~2,000 | ~4,000+ |
| **Cost/run*** | $0.003 | $0.003 | $0.006 | $0.012+ |
| **20 iterations** | $0.06 | $0.06 | $0.12 | $0.24+ |
| **100 iterations** | $0.30 | $0.30 | $0.60 | $1.20+ |

<sub>*Based on Claude Sonnet input pricing ($3/1M tokens). Output costs additional.</sub>

**How we do it:**
- Symbol compression (`∅` = empty, `→` = then)
- Zero redundancy (LLMs already know how to code)
- Dynamic loading (only the agent you need)
- Shared state reference (one `STATE.md`, not duplicated everywhere)

**Your savings over 1,000 builds: ~$9** (or more with GPT-4/Claude Opus)

---

## Choose Your Tier

| | [Shard](./shard/) | [Array](./array/) | [Matrix](./matrix/) |
|---|-----------------|-----------------|-------------------|
| **Files** | 1 | 6 + agents/ | 6 + agents/ + enterprise/ |
| **Lines** | ~180 | ~260 | ~600 |
| **Tokens/run** | ~1,100 | ~1,000 | ~2,000 |
| **Agents** | 1 (modes) | 4 (specialized) | 9+ (coordinated) |
| **Complexity** | Minimal | Moderate | Enterprise |
| **Best for** | Solo devs | Teams | Enterprise |

---

## Shard (One File)

> *A single fragment. All you need to get started.*

```bash
cp shard/mothership.md .mothership/
```

```
"Read .mothership/mothership.md and run: plan user auth"
"Read .mothership/mothership.md and run: build"
```

~180 lines, ~1,100 tokens. Modes: plan, build, test, review.

**[→ Shard Docs](./shard/README.md)**

---

## Array (Specialized Agents)

> *An organized collection. Teams working together.*

```bash
cp -r array/ .mothership/
```

```
"Read .mothership/mothership.md and run: plan user auth"   # Cipher
"Read .mothership/mothership.md and run: build"            # Vector
"Read .mothership/mothership.md and run: test"             # Cortex
"Read .mothership/mothership.md and run: review"           # Sentinel
```

4 specialized agents, ~30 lines each. ~1,000 tokens per run.

**[→ Array Docs](./array/README.md)**

---

## Matrix (Enterprise)

> *The interconnected grid. Enterprise-grade orchestration.*

```bash
cp -r matrix/ .mothership/
```

**Core Agents:** Cipher, Vector, Cortex, Sentinel

**Enterprise Agents:**
- **Arbiter** - Conflict resolution
- **Conductor** - Multi-service deployment
- **Coalition** - Multi-team coordination
- **Vault** - Secrets management
- **Telemetry** - Analytics & compliance

Features: governance, approvals, multi-service deployments, secret scanning, DORA metrics.

**[→ Matrix Docs](./matrix/README.md)**

---

## Agent Reference

### Core Agents

| Agent | Role | Signal |
|-------|------|--------|
| **Cipher** | Planning - decodes requirements into stories | `<cipher>P:N</cipher>` |
| **Vector** | Building - constructs code from stories | `<vector>B:ID</vector>` |
| **Cortex** | Testing - analyzes with chaos tests | `<cortex>T:ID</cortex>` |
| **Sentinel** | Review - guards code quality | `<sentinel>A</sentinel>` |

### Optional Agents

| Agent | Role | Signal |
|-------|------|--------|
| **Pulse** | Deployment | `<pulse>D</pulse>` |
| **Nexus** | Prioritization | `<nexus>P:N</nexus>` |
| **Vigil** | Monitoring | `<vigil>H</vigil>` |
| **Archive** | Documentation | `<archive>D:F</archive>` |
| **Purge** | Tech debt cleanup | `<purge>K:S</purge>` |

### Enterprise Agents (Matrix only)

| Agent | Role | Signal |
|-------|------|--------|
| **Arbiter** | Conflict resolution | `<arbiter>R:IDs</arbiter>` |
| **Conductor** | Deployment orchestration | `<conductor>D:S</conductor>` |
| **Coalition** | Multi-team coordination | `<coalition>C:T</coalition>` |
| **Vault** | Secrets management | `<vault>S:N</vault>` |
| **Telemetry** | Analytics & metrics | `<telemetry>R:P</telemetry>` |

---

## What's Better Than Ralph?

[Ralph](https://github.com/snarktank/ralph) is brilliant: one prompt, one loop, ship code.

Mothership keeps that simplicity and adds:

| Ralph Lacks | Mothership Has |
|-------------|----------------|
| Planning | `plan` mode/Cipher creates stories |
| Testing | `test` mode/Cortex writes chaos tests |
| Review | `review` mode/Sentinel checks quality |
| Recovery | Checkpoint for context loss |
| Patterns | codebase.md persists learnings |
| GitHub Action | CI/CD integration out of the box |
| Multi-backend | 6 state adapters (not just JSON) |
| Enterprise | Matrix tier with governance & multi-service |

---

## How It Works

1. **State anywhere** - Linear, Jira, GitHub Issues, or local JSON
2. **One task per run** - Fresh context, focused work
3. **Checkpoint recovery** - Resume after context loss
4. **Pattern memory** - codebase.md carries learnings

---

## Linear Setup

Connect Mothership to Linear to auto-create projects, milestones, and issues from your docs.

### 1. Install & Authenticate
```bash
npm install -g @linear/cli
linear auth
```

### 2. Configure
Edit `.mothership/config.json`:
```json
{
  "state": "linear",
  "linear": {
    "team": "ENG"
  }
}
```
Find your team key: `linear team list`

### 3. Add Your Docs
Put your PRD, spec, or requirements in `./docs/`:
```
docs/
├── auth.md          # Feature requirements
├── onboarding.md    # Another feature
└── api-spec.md      # Technical spec
```

### 4. Run Plan
```bash
./mothership.sh plan "user authentication"
```

Cipher will:
- Read your docs
- Create a Linear **Project** for the feature
- Create **Milestones** for each phase/section
- Create **Issues** for each user story
- Set all issues to "Ready"

### Example

**Input (`docs/auth.md`):**
```markdown
# User Authentication

## Phase 1: Basic Login
- User can log in with email/password
- User can reset password via email

## Phase 2: OAuth
- User can log in with Google
- User can log in with GitHub
```

**Output in Linear:**
```
Project: User Authentication
├── Milestone: Phase 1 - Basic Login
│   ├── Issue: User can log in with email/password
│   └── Issue: User can reset password via email
└── Milestone: Phase 2 - OAuth
    ├── Issue: User can log in with Google
    └── Issue: User can log in with GitHub
```

**[→ Full Linear Adapter Docs](./adapters/state/linear.md)**

---

## Credits

Built on ideas from:
- [Geoffrey Huntley](https://ghuntley.com/ralph/) - Original Ralph concept
- [Ryan Carson](https://github.com/snarktank/ralph) - Ralph implementation

See [CREDITS.md](./CREDITS.md) for the full story.

---

## Contributing

PRs welcome. See [CONTRIBUTING.md](./CONTRIBUTING.md).

**Marketing & Launch:** See [marketing/](./marketing/) for launch materials, video script, and roadmap.

---

## License

MIT - Use it, modify it, ship it.

---

*"I come in peace. I leave with features."* 🛸
