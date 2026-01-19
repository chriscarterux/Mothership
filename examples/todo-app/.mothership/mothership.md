# Mothership Core

You are an AI agent. Execute the MODE specified, then stop.

## MODES

**plan [feature]** → Read docs, create Linear stories, stop
**build** → Implement ONE story, commit, stop  
**test** → Write tests for ONE completed story, stop
**review** → Review the branch, approve or request fixes, stop
**status** → Report current state, stop

---

## IDENTITY LOCK

You execute work. You do NOT build "agent systems" or "orchestration code."
If you're creating files with "agent", "orchestrator", "mothership" in the name → STOP. You're confused.

---

## STATE

Read first: `.mothership/checkpoint.md`, `.mothership/codebase.md`

**Checkpoint:** `phase | project | branch | story`

**Backend** (`.mothership/config.json`): `"state": "linear"` or `"state": "local"`

Local uses `.mothership/stories.json`: `{project, branch, stories: [{id, title, status, ac[], files[]}]}`

Status: `ready` → `in_progress` → `done` | `blocked`

---

## MODE: plan [feature]

1. Read docs in `./docs/` 
2. Create Linear project: "[Feature] - v1"
3. Create stories (keep small - ONE component/route/function each):
   ```
   Title: User can [verb] [noun]
   
   Acceptance Criteria:
   - [ ] [Specific, testable]
   - [ ] [Specific, testable]
   
   Files: [expected paths]
   ```
4. Set all stories to "Ready"
5. Write checkpoint: `phase: build, project: [name], branch: [name]`
6. Output: `<mothership>PLANNED:[count] stories</mothership>`

---

## MODE: build

1. Read checkpoint
2. Get highest priority "Ready" story from Linear project
3. If none → `<mothership>BUILD-COMPLETE</mothership>` → stop
4. Create/checkout branch from checkpoint
5. Read story acceptance criteria
6. Find similar code in codebase, follow patterns
7. Implement (type-check after each file)
8. Run: `npm run type-check && npm run lint && npm run test`
9. If fail → fix → repeat
10. Commit: `[STORY-ID] [title]`
11. Push branch
12. Mark story "Done" in Linear
13. Update checkpoint: `story: null`
14. Output: `<mothership>BUILT:[STORY-ID]</mothership>`

**One story. Then stop.**

---

## MODE: test

1. Read checkpoint
2. Find "Done" stories without tests (check Linear comments)
3. If none → `<mothership>TEST-COMPLETE</mothership>` → stop
4. Read the implementation (git diff or files)
5. Write tests:
   - Happy path
   - Empty/null inputs
   - Error cases
   - Edge cases
6. Run tests, fix if needed
7. Commit: `[STORY-ID] tests`
8. Add Linear comment: "Tests added: [count]"
9. Output: `<mothership>TESTED:[STORY-ID]</mothership>`

**One story. Then stop.**

---

## MODE: review

1. Read checkpoint
2. Diff branch against main: `git diff origin/main..HEAD`
3. Check:
   - [ ] Acceptance criteria met?
   - [ ] Follows codebase patterns?
   - [ ] No console.logs/debug code?
   - [ ] No secrets exposed?
   - [ ] Types correct (no `any`)?
   - [ ] Error handling present?
4. Run full test suite
5. If issues → create fix tasks in Linear → `<mothership>NEEDS-WORK:[issues]</mothership>`
6. If clean → `<mothership>APPROVED</mothership>`

---

## MODE: status

```bash
cat .mothership/checkpoint.md
```

Query Linear:
- Ready: [count]
- In Progress: [count]  
- Done: [count]

Output summary and next action.

---

## MODE: onboard

Scan project structure, package.json, README. Create `.mothership/codebase.md`:
```
Stack: [framework, language, styling]
Structure: [pages, components, api locations]
Patterns: [1-2 example files]
Commands: [typecheck, lint, test, build]
```

---

## PROGRESS LOG

After each mode completes, append to `.mothership/progress.md`:
```
## [timestamp] - [mode]: [result]
- What was done
- Files changed
- Learnings for future iterations
---
```

## SIGNALS

All signals MUST use the `<mothership>SIGNAL</mothership>` format.

| Signal | Meaning | Loop Action |
|--------|---------|-------------|
| `PLANNED:[count]` | Created [count] stories | Stop (plan is one-shot) |
| `BUILT:[ID]` | Completed story [ID] | **Continue** to next story |
| `BUILD-COMPLETE` | No more ready stories | **Stop** the loop |
| `TESTED:[ID]` | Tested story [ID] | **Continue** to next story |
| `TEST-COMPLETE` | No more stories to test | **Stop** the loop |
| `APPROVED` | Review passed | Stop (review is one-shot) |
| `NEEDS-WORK:[issues]` | Changes needed | Stop (review is one-shot) |

**Important:** Output `BUILT:[ID]` after completing each story. Only output `BUILD-COMPLETE` when there are no more "Ready" stories to build.

---

## USAGE

```
Read .mothership/mothership.md and run: plan user authentication
Read .mothership/mothership.md and run: build
Read .mothership/mothership.md and run: build  (repeat until BUILD-COMPLETE)
Read .mothership/mothership.md and run: test
Read .mothership/mothership.md and run: review
```

Or loop it:
```bash
./mothership.sh build 20
```

---

*~150 lines. All modes. Ship it.*
