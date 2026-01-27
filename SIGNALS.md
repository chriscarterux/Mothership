# Signal Reference

Signals indicate agent completion status. All signals MUST use the format: `<agent>SIGNAL</agent>`

## Agent Names

| Agent | Role | Modes |
|-------|------|-------|
| `mothership` | Unified agent (single file mode) | All modes |
| `cipher` | Planning | plan |
| `vector` | Building | build |
| `cortex` | Testing | test |
| `sentinel` | Review/Environment | review, verify-env |
| `atomic` | Wiring verification | verify |
| `sanity` | Quick checks | quick-check |
| `nexus` | Test matrix/contracts | test-matrix, test-contracts |
| `phoenix` | Rollback testing | test-rollback |
| `scanner` | Inventory/discovery | inventory |
| `pulse` | Health checks | health-check |

## Development Mode Signals

| Agent | Signal | Meaning | Loop Action |
|-------|--------|---------|-------------|
| cipher | `PLANNED:N` | Planned N stories | Stop (one-shot) |
| vector | `BUILT:ID` | Built story ID | **Continue** |
| vector | `BUILD-COMPLETE` | No more stories to build | **Stop** |
| vector | `BLOCKED:ID:R` | Blocked on ID, reason R | Stop |
| cortex | `TESTED:ID` | Tested story ID | **Continue** |
| cortex | `TEST-COMPLETE` | All stories tested | **Stop** |
| sentinel | `APPROVED` | Code review passed | Stop (one-shot) |
| sentinel | `NEEDS-WORK` | Changes required | Stop (one-shot) |

## Verification Mode Signals

| Agent | Signal | Meaning | Loop Action |
|-------|--------|---------|-------------|
| sanity | `QUICK-CHECK:pass` | No issues found | Stop |
| sanity | `QUICK-CHECK:fail:[count]` | Found issues | Stop |
| atomic | `VERIFIED:[ID]` | Runtime verification passed | Stop |
| atomic | `UNWIRED:[ID]:[issues]` | Found unwired/broken code | Stop |
| nexus | `MATRIX-PASS:[ID]` | All test layers passed | Stop |
| nexus | `MATRIX-FAIL:[ID]:[layers]` | Test layers failed | Stop |
| nexus | `CONTRACTS-VALID` | All API contracts pass | Stop |
| nexus | `CONTRACTS-VIOLATED:[count]` | Contract violations found | Stop |
| nexus | `BREAKING-CHANGES:[count]` | Breaking API changes detected | Stop |
| phoenix | `ROLLBACK-VERIFIED` | Rollback procedures work | Stop |
| phoenix | `ROLLBACK-FAILED:[component]` | Rollback test failed | Stop |

## Infrastructure Mode Signals

| Agent | Signal | Meaning | Loop Action |
|-------|--------|---------|-------------|
| sentinel | `ENV-VERIFIED` | Environment properly configured | Stop |
| sentinel | `ENV-FAILED:[count]` | Environment issues found | Stop |
| pulse | `HEALTHY` | All integrations healthy | Stop |
| pulse | `UNHEALTHY:[services]` | Integration failures | Stop |
| scanner | `INVENTORY-COMPLETE:[counts]` | Codebase inventory done | Stop |
| scanner | `STORIES-GENERATED:[count]` | Test stories created | Continue |

## Utility Mode Signals

| Agent | Signal | Meaning | Loop Action |
|-------|--------|---------|-------------|
| mothership | `STATUS-COMPLETE` | Status reported | Stop |
| mothership | `ONBOARD-COMPLETE` | Codebase.md created | Stop |
| any | `BLOCKED` | Agent is blocked | Stop |

## Default Mode (Single File)

When using the default `mothership.md`, signals use the `<mothership>` tag:

| Signal | Meaning | Loop Action |
|--------|---------|-------------|
| `<mothership>PLANNED:N</mothership>` | Planned N stories | Stop (one-shot) |
| `<mothership>BUILT:ID</mothership>` | Built story ID | **Continue** to next story |
| `<mothership>BUILD-COMPLETE</mothership>` | No more stories | **Stop** the loop |
| `<mothership>TESTED:ID</mothership>` | Tested story ID | **Continue** to next story |
| `<mothership>TEST-COMPLETE</mothership>` | All tested | **Stop** the loop |
| `<mothership>APPROVED</mothership>` | Review passed | Stop (one-shot) |
| `<mothership>NEEDS-WORK</mothership>` | Changes needed | Stop (one-shot) |
| `<mothership>QUICK-CHECK:pass</mothership>` | No issues | Stop |
| `<mothership>VERIFIED:ID</mothership>` | Wiring verified | Stop |
| `<mothership>MATRIX-PASS:ID</mothership>` | All tests pass | Stop |
| `<mothership>ENV-VERIFIED</mothership>` | Environment OK | Stop |
| `<mothership>HEALTHY</mothership>` | Integrations OK | Stop |
| `<mothership>INVENTORY-COMPLETE</mothership>` | Inventory done | Stop |
| `<mothership>ROLLBACK-VERIFIED</mothership>` | Rollback works | Stop |

## Signal Detection

The `mothership.sh` loop detects signals in the `<agent>SIGNAL</agent>` format:

```bash
# Build mode continues on BUILT:*, stops on:
BUILD-COMPLETE

# Test mode continues on TESTED:*, stops on:
TEST-COMPLETE

# Plan mode (one iteration) stops on:
PLANNED:[0-9]+

# Review mode (one iteration) stops on:
APPROVED | NEEDS-WORK

# Verification modes (one iteration) stop on:
QUICK-CHECK:pass | QUICK-CHECK:fail
VERIFIED | UNWIRED
MATRIX-PASS | MATRIX-FAIL
CONTRACTS-VALID | CONTRACTS-VIOLATED | BREAKING-CHANGES
ROLLBACK-VERIFIED | ROLLBACK-FAILED

# Infrastructure modes (one iteration) stop on:
ENV-VERIFIED | ENV-FAILED
HEALTHY | UNHEALTHY
INVENTORY-COMPLETE
```

## Agent Handoff Pattern

Agents hand off to each other through the workflow:

```
┌─────────────────────────────────────────────────────────────────────────┐
│  AGENT HANDOFF FLOW                                                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  [onboard] ──ONBOARD-COMPLETE──→ [inventory] ──INVENTORY-COMPLETE──→    │
│                                                                          │
│  [cipher/plan] ──PLANNED:N──→ [vector/build] ──BUILT:ID──→ (loop)       │
│                                   │                                      │
│                            BUILD-COMPLETE                                │
│                                   ↓                                      │
│  [sanity/quick-check] ──pass──→ [atomic/verify] ──VERIFIED──→           │
│                                                                          │
│  [nexus/test-matrix] ──MATRIX-PASS──→ [nexus/test-contracts] ──VALID──→ │
│                                                                          │
│  [cortex/test] ──TESTED:ID──→ (loop until TEST-COMPLETE) ──→            │
│                                                                          │
│  [sentinel/review] ──APPROVED──→                                         │
│                                                                          │
│  [sentinel/verify-env] ──ENV-VERIFIED──→ [phoenix/test-rollback] ──→    │
│                                                                          │
│  [deploy] ──→ [pulse/health-check] ──HEALTHY──→ ✅ DONE                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

**Important:**
- `BUILT:ID` signals a story is complete but the loop **continues** to the next story
- `BUILD-COMPLETE` signals there are no more stories, so the loop **stops**
- Same pattern applies for `TESTED:ID` vs `TEST-COMPLETE`
- Verification modes are one-shot (stop on any terminal signal)
- Failure signals (UNWIRED, MATRIX-FAIL, etc.) stop the workflow for fixes

## Manual Handoff

When running modes manually without the loop:

```bash
# Full workflow
./mothership.sh onboard
./mothership.sh inventory
./mothership.sh plan "user authentication"
./mothership.sh build 20        # Loops until BUILD-COMPLETE
./mothership.sh quick-check
./mothership.sh verify
./mothership.sh test-matrix
./mothership.sh test-contracts
./mothership.sh test 20         # Loops until TEST-COMPLETE
./mothership.sh review
./mothership.sh verify-env
./mothership.sh test-rollback
# deploy (manual or CI/CD)
./mothership.sh health-check
```
