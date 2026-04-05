# Mothership

You are an AI agent. Execute the MODE specified, then stop.

## MODES

### Development Modes
**plan [feature]** → Read docs, create Linear stories with ATOMIC acceptance criteria, stop
**build** → Implement ONE story, VERIFY WIRING, commit, stop
**test** → Write tests for ONE completed story, stop
**review** → Review the branch, approve or request fixes, stop

### Verification Modes
**quick-check** → Fast sanity check for common misses (unwired UI, crashed containers), stop
**verify** → Runtime verification that code actually works, stop
**test-matrix** → Comprehensive test coverage (Unit, Integration, API, E2E, Security, A11y), stop
**test-contracts** → API contract testing between frontend/backend/services, stop
**test-rollback** → Verify rollback procedures work before deployment, stop

### Infrastructure Modes
**verify-env** → Check env vars, services, certificates before deployment, stop
**health-check** → Verify all integrations are working (DB, Stripe, Email, AI), stop
**inventory** → Discover and catalog all APIs, components, integrations, stop

### Utility Modes
**status** → Report current state, stop
**onboard** → Scan project, create codebase.md, stop

---

## IDENTITY LOCK

You execute work. You do NOT build "agent systems" or "orchestration code."
If you're creating files with "agent", "orchestrator", "mothership" in the name → STOP. You're confused.

---

## STATE

Read first: `.mothership/checkpoint.md`, `.mothership/codebase.md`

**Checkpoint:** `phase | project | branch | story`

**Backend** (`.mothership/config.json`): `"state": "linear"` or `"state": "local"` or `"state": "trello"`

Local uses `.mothership/stories.json`: `{project, branch, stories: [{id, title, status, ac[], files[]}]}`

### Trello Backend

When `"state": "trello"`, read stories from Trello cards via REST API.

**Config** (`.mothership/config.json`):
```json
{
  "state": "trello",
  "trello": {
    "board_id": "SHORT_BOARD_ID",
    "lists": { "ready": "Backlog", "in_progress": "Active Request", "done": "Approved" },
    "list_ids": { "ready": "LIST_ID", "in_progress": "LIST_ID", "done": "LIST_ID" }
  }
}
```

**Auth:** Uses env vars `TRELLO_API_KEY` and `TRELLO_TOKEN` from `.env.local`.

**Reading stories (get next ready):**
```bash
curl -s "https://api.trello.com/1/lists/${LIST_ID_READY}/cards?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}&fields=name,desc,labels" | jq '.[0]'
```
Card `name` = story title, `desc` = acceptance criteria (markdown checklist).

**Moving cards (update status):**
```bash
curl -s -X PUT "https://api.trello.com/1/cards/${CARD_ID}" \
  --data-urlencode "key=${TRELLO_API_KEY}" \
  --data-urlencode "token=${TRELLO_TOKEN}" \
  --data-urlencode "idList=${TARGET_LIST_ID}"
```

**Adding comments:**
```bash
curl -s -X POST "https://api.trello.com/1/cards/${CARD_ID}/actions/comments" \
  --data-urlencode "key=${TRELLO_API_KEY}" \
  --data-urlencode "token=${TRELLO_TOKEN}" \
  --data-urlencode "text=Implementation complete."
```

**Mapping:** Trello List → status (`ready`/`in_progress`/`done`), Trello Label → service line, Trello Card → story, Trello Checklist → acceptance criteria.

Status: `ready` → `in_progress` → `done` | `blocked`

---

## MODE: plan [feature]

1. Read docs in `./docs/`
2. Create stories in state backend:
   - **Linear:** Create Linear project "[Feature] - v1", add stories as issues
   - **Trello:** Create cards in the Backlog list with checklist for acceptance criteria
   - **Local:** Write to `.mothership/stories.json`
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
2. Get highest priority "Ready" story from state backend:
   - **Linear:** Query Linear project for ready issues
   - **Trello:** `curl` the Backlog list for the first card (see STATE section)
   - **Local:** Read `.mothership/stories.json` for first `ready` story
3. If none → `<mothership>BUILD-COMPLETE</mothership>` → stop
4. Create/checkout branch from checkpoint
5. Read story acceptance criteria
6. Find similar code in codebase, follow patterns
7. Implement (type-check after each file)
8. Run commands from `.mothership/config.json` (if exists):
   - `commands.typecheck`
   - `commands.lint`
   - `commands.test`
   Default (no config): `npm run typecheck && npm run lint && npm run test`
9. If fail → fix → repeat
10. **WIRING VALIDATION (CRITICAL):**
    - UI: Check no empty handlers (`grep -rn "onClick={}" src/`)
    - UI: Verify handlers call real functions (not just console.log)
    - API: Start server, test endpoint responds (not 500/404)
    - Docker: Build image, run container, verify stays running 30s+
    - DB: Run migration, verify schema changes applied
11. Commit: `[STORY-ID] [title]`
12. Push branch
13. Mark story "Done" in state backend (Linear: update issue, Trello: move card to done list, Local: update JSON)
14. Update checkpoint: `story: null`
15. Output: `<mothership>BUILT:[STORY-ID]</mothership>`

**One story. Then stop.**

---

## MODE: quick-check

Fast sanity check for the most common issues:

1. **UI Wiring:**
   ```bash
   grep -rn "onClick={}\|onSubmit={}\|() => {}" src/
   ```
   Any output = FAIL

2. **Docker Runs:**
   ```bash
   docker build -t qc . && docker run -d --name qc-test qc
   sleep 15 && docker ps | grep qc-test  # Should show "Up"
   ```

3. **Build Works:**
   ```bash
   npm run build
   ```

4. **Tests Pass:**
   ```bash
   npm test
   ```

Output: `<mothership>QUICK-CHECK:[pass/fail]:[count] issues</mothership>`

---

## MODE: verify

Runtime verification that implementation actually works:

1. Read checkpoint, identify story type (UI, API, Docker, DB)
2. Run type-specific verification:

**UI Stories:**
- Start dev server
- Component renders without error
- Click handlers fire (check network tab)
- Forms submit data
- Navigation works

**API Stories:**
- Start server
- `curl` each new endpoint
- Verify response shape
- Test error cases (400, 401, 404)

**Docker Stories:**
- Build image
- Run container
- Verify stays up 30+ seconds
- Health check passes
- Logs show startup complete

**DB Stories:**
- Run migration
- Query to verify schema
- Test rollback

Output: `<mothership>VERIFIED:[story-id]</mothership>` or `<mothership>UNWIRED:[story-id]:[issues]</mothership>`

---

## MODE: test-matrix

Comprehensive test coverage across ALL layers:

| Layer | Required For | Checks |
|-------|--------------|--------|
| Unit | All code | Functions in isolation, edge cases |
| Integration | Multi-component | Components work together |
| API | Any API | Contracts, validation, auth |
| E2E | User flows | Full journeys work |
| Security | All code | XSS, injection, auth, secrets |
| A11y | UI code | WCAG 2.1 AA compliance |

Run each applicable layer. ALL must pass before review.

Output: `<mothership>MATRIX-PASS:[story-id]</mothership>` or `<mothership>MATRIX-FAIL:[story-id]:[layers]</mothership>`

---

## MODE: test

1. Read checkpoint
2. Find "Done" stories without tests (check state backend comments/checklists)
3. If none → `<mothership>TEST-COMPLETE</mothership>` → stop
4. Read the implementation (git diff or files)
5. Write tests:
   - Happy path
   - Empty/null inputs
   - Error cases
   - Edge cases
6. Run tests, fix if needed
7. Commit: `[STORY-ID] tests`
8. Add comment to state backend: "Tests added: [count]" (Linear comment / Trello card comment / local JSON)
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
5. If issues → create fix tasks in state backend (Linear issues / Trello cards / local JSON) → `<mothership>NEEDS-WORK:[issues]</mothership>`
6. If clean → `<mothership>APPROVED</mothership>`

---

## MODE: status

```bash
cat .mothership/checkpoint.md
```

Query state backend (Linear issues / Trello cards / local JSON):
- Ready: [count]
- In Progress: [count]
- Done: [count]

Output summary and next action.
Output: `<mothership>STATUS-COMPLETE</mothership>`

---

## MODE: onboard

Scan project structure, package.json, README. Create `.mothership/codebase.md`:
```
Stack: [framework, language, styling]
Structure: [pages, components, api locations]
Patterns: [1-2 example files]
Commands: [typecheck, lint, test, build]
```
Output: `<mothership>ONBOARD-COMPLETE</mothership>`

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
| `QUICK-CHECK:pass` | No common issues found | Continue |
| `QUICK-CHECK:fail:[count]` | Found [count] issues | **Stop** and fix |
| `VERIFIED:[ID]` | Runtime verification passed | Continue |
| `UNWIRED:[ID]:[issues]` | Found unwired/broken code | **Stop** and fix |
| `MATRIX-PASS:[ID]` | All test layers passed | Continue |
| `MATRIX-FAIL:[ID]:[layers]` | Test layers failed | **Stop** and fix |
| `TESTED:[ID]` | Tested story [ID] | **Continue** to next story |
| `TEST-COMPLETE` | No more stories to test | **Stop** the loop |
| `CONTRACTS-VALID` | All API contracts pass | Continue |
| `CONTRACTS-VIOLATED:[count]` | Contract violations found | **Stop** and fix |
| `BREAKING-CHANGES:[count]` | Breaking API changes detected | **Stop** and review |
| `ROLLBACK-VERIFIED` | Rollback procedures tested | Continue |
| `ROLLBACK-FAILED:[component]` | Rollback test failed | **Stop** and fix |
| `ENV-VERIFIED` | Environment properly configured | Continue |
| `ENV-FAILED:[count]` | Environment issues found | **Stop** and fix |
| `HEALTHY` | All integrations healthy | Continue |
| `UNHEALTHY:[services]` | Integration failures | **Stop** and fix |
| `INVENTORY-COMPLETE:[counts]` | Codebase inventory done | Stop (one-shot) |
| `APPROVED` | Review passed | Stop (review is one-shot) |
| `NEEDS-WORK:[issues]` | Changes needed | Stop (review is one-shot) |
| `STATUS-COMPLETE` | Status reported | Stop (status is one-shot) |
| `ONBOARD-COMPLETE` | Codebase.md created | Stop (onboard is one-shot) |
| `BLOCKED` | Agent is blocked | **Stop** and report |

**Important:** Output `BUILT:[ID]` after completing each story. Only output `BUILD-COMPLETE` when there are no more "Ready" stories to build.

---

## COMPLETE WORKFLOW

The full workflow with ALL verification phases:

```
┌─────────────────────────────────────────────────────────────────────────┐
│  DEVELOPMENT FLOW                                                        │
├─────────────────────────────────────────────────────────────────────────┤
│  onboard → inventory → plan → build → quick-check → verify              │
│                                  ↓                                       │
│            test-matrix → test-contracts → test → review                 │
│                                  ↓                                       │
│  PRE-DEPLOY: verify-env → test-rollback → deploy → health-check         │
└─────────────────────────────────────────────────────────────────────────┘
```

Each phase MUST pass before proceeding:

| Phase | What It Checks | Failure = |
|-------|----------------|-----------|
| onboard | Project scanned, codebase.md created | Can't proceed |
| inventory | All APIs/components discovered | Missing test coverage |
| plan | Stories have atomic AC with verification steps | Can't build |
| build | Code compiles, lints, basic tests | Can't proceed |
| quick-check | No empty handlers, containers run | Back to build |
| verify | Runtime verification, APIs respond | Back to build |
| test-matrix | Unit, Integration, API, E2E, Security, A11y | Back to build |
| test-contracts | API contracts honored | Back to build |
| test | Specific story tests pass | Back to build |
| review | Code quality, patterns, security | Back to build |
| verify-env | Env vars, services, certs configured | Can't deploy |
| test-rollback | Rollback procedures work | Can't deploy |
| deploy | Code deployed to environment | Rollback |
| health-check | All integrations healthy | Rollback |

## CRITICAL: Story Types Must Include

Every story MUST specify tests for ALL applicable layers:

**Frontend stories MUST test:**
- [ ] Component renders
- [ ] Event handlers wired (onClick calls real function)
- [ ] Forms submit to API
- [ ] Navigation works
- [ ] Accessibility (keyboard, screen reader)

**Backend stories MUST test:**
- [ ] Endpoint responds (not 500/404)
- [ ] Returns expected shape
- [ ] Validates input (400 on bad data)
- [ ] Auth checked (401/403)
- [ ] Database operations execute

**Full-stack stories MUST test:**
- [ ] ALL frontend checks
- [ ] ALL backend checks
- [ ] Integration between them works

**Infrastructure stories MUST test:**
- [ ] Container builds
- [ ] Container runs 30+ seconds
- [ ] Health check passes
- [ ] Logs show startup

## USAGE

```
Read .mothership/mothership.md and run: plan user authentication
Read .mothership/mothership.md and run: build
Read .mothership/mothership.md and run: quick-check
Read .mothership/mothership.md and run: verify
Read .mothership/mothership.md and run: test-matrix
Read .mothership/mothership.md and run: test
Read .mothership/mothership.md and run: review
```

Or loop it:
```bash
./m build 20
```

---

*Complete verification pipeline. Nothing ships broken.*
