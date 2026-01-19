# Example: Camino Journaling App

This example shows Mothership Core building a feature for a journaling/personal development app.

## The Project

**Camino** is a personal development platform with:
- 3 programs: Discover ($9.95/mo), Journey ($39.95/mo), The Camino Method ($1,997)
- AI-guided reflections
- Daily prompts across Identity, Worldview, Relationship dimensions

## The Feature

We'll build: **User Onboarding Flow**

The user should be able to:
1. See a welcome screen explaining the programs
2. Choose a program tier
3. Complete initial assessment
4. Start their first reflection

## Try It

```bash
cd example

# Verify setup
../mothership.sh doctor

# Check token usage
../mothership.sh benchmark

# Plan the feature
"Read .mothership/mothership.md and run: plan user onboarding flow"

# Build stories one at a time (loops until done)
../mothership.sh build 10

# Test
../mothership.sh test 10

# Review
"Read .mothership/mothership.md and run: review"
```

### Optional: Add Specialized Agents

If you want dedicated agents for each mode:

```bash
cp ../agents/*.md .mothership/agents/
```

## Files

```
example/
├── .mothership/
│   ├── mothership.md    # The prompt
│   ├── config.json      # Settings (Linear or local)
│   └── checkpoint.md    # Current state (auto-created)
├── docs/
│   └── onboarding.md    # Feature requirements
├── package.json         # Project config
└── README.md            # This file
```

## Expected Output

After `plan`:
- 4-6 stories created in Linear (or stories.json)
- Checkpoint updated to `phase: build`

After `build` (repeat until COMPLETE):
- Each story implemented
- Code committed to branch
- Stories marked Done

After `test`:
- Tests written for each story
- Edge cases covered

After `review`:
- APPROVED or NEEDS-WORK signal
- Ready to merge
