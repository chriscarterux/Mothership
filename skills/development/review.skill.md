# Skill: Review

Multi-perspective code review with Model Council synthesis.

## Context
- Read `.mothership/checkpoint.md` for current state
- Read `.mothership/config.json` for state backend
- Argument: file path, commit hash, directory, or story ID

## Steps

### 1. Determine Scope

- If argument provided → review specific file/commit/directory
- If `.mothership/checkpoint.md` has active story → review that story's changes
- Otherwise → review uncommitted changes (`git diff`)

### 2. Architecture Review

- Code organization and structure
- Separation of concerns
- Coupling and cohesion
- Design patterns (appropriate use or missed opportunities)
- Naming conventions

### 3. Security Review

- XSS vulnerabilities
- SQL injection
- SSRF / request forgery
- Hardcoded secrets or credentials
- Authentication and authorization checks
- Input sanitization and validation

### 4. Performance Review

- Algorithm efficiency (flag O(n²) or worse)
- N+1 query patterns
- Memory leaks or unbounded growth
- Bundle size impact (frontend)
- Unnecessary re-renders (React/UI)
- Async operations handled properly

### 5. Best Practices

- Error handling completeness
- Logging and observability
- Test coverage gaps
- Code readability and maintainability

### 6. Acceptance Criteria Verification

If story context is available:
- Verify all AC are met
- Check edge cases are handled
- Confirm tests cover requirements

### 7. Model Council

**Skip if trivial:** docs-only changes, config-only changes, or <20 lines changed.

Run 3 parallel reviews using different model perspectives:

#### 7a. Ollama Architecture Review
```
mcp__ollama-remote__ollama_code_review
```
Uses the best available model (qwen2.5:32b or similar) for architecture and code quality review.

#### 7b. Claude Deep Analysis
```
Agent subagent (subagent_type: general-purpose)
```
Comprehensive review covering: architecture, security, reliability, performance, type safety, migration quality, and test coverage gaps.

#### 7c. Ollama Security Review
```
mcp__ollama-remote__ollama_code_review
```
Security-focused prompts: injection, SSRF, auth bypass, race conditions, data exposure.

#### 7d. Graceful Degradation

If Ollama is unavailable (MCP server not connected, remote host down, no models loaded):

- **Skip steps 7a and 7c** — do not error or block the review
- **Proceed with step 7b only** (Claude deep analysis)
- **Note in report:** Council ran in degraded mode (1/3 reviewers)
- Verdict still applies but with lower confidence — note `(degraded: Ollama unavailable)` in the verdict line

If Claude subagent also fails, fall back to the standard review from steps 2-6 (no council).

#### 7e. Synthesize

Combine all available reviews into a single consolidated report:
- Deduplicate findings across reviewers
- Severity-rank: High → Medium → Low
- Note which findings were flagged by multiple reviewers (higher confidence)
- Produce a **Council Verdict**: APPROVE / REQUEST_CHANGES / COMMENT
- List concrete, actionable findings
- If degraded, note how many reviewers participated

### 8. Update State

**If Trello:** Post the review report as a comment on the active card.
**If Local:** Output the report (advisory only — no file to update).

### 9. Update Checkpoint

If approved → update checkpoint phase to `deploy`.

## Council Report Format

```markdown
# Model Council Review — [branch-name]
## Council Verdict: [APPROVE/REQUEST_CHANGES] ([unanimous/majority])

## Consolidated Findings
| # | Severity | Finding | Flagged By |
|---|----------|---------|:----------:|
| 1 | High | [description] | Claude + Ollama |
| 2 | Medium | [description] | Claude |

## Strengths Highlighted
- [Patterns praised by multiple reviewers]

## Recommendation
[Merge-ready / Fix N items first / Needs rework]
```

## Review Checklist

### Code Quality
- [ ] Functions are small and focused
- [ ] Variable names are meaningful
- [ ] No magic numbers or strings
- [ ] Error handling is appropriate
- [ ] No unnecessary complexity

### Security
- [ ] No SQL injection vulnerabilities
- [ ] No XSS vulnerabilities
- [ ] Input is validated
- [ ] Secrets are not hardcoded
- [ ] Authentication is checked

### Performance
- [ ] No N+1 query patterns
- [ ] Efficient data structures used
- [ ] No memory leaks
- [ ] Async operations handled properly

### Testing
- [ ] Unit tests exist and pass
- [ ] Edge cases are tested
- [ ] Error paths are tested

## Output Signal

**Approved:**
```
<mothership>APPROVED</mothership>
```

**Approved with council:**
```
<mothership>COUNCIL-APPROVED:[unanimous/majority]</mothership>
```

**Needs work:**
```
<mothership>NEEDS-WORK:[issues summary]</mothership>
```

## Signals

| Signal | Meaning |
|--------|---------|
| `APPROVED` | Review passed (no council or trivial) |
| `COUNCIL-APPROVED:[consensus]` | Council review passed |
| `NEEDS-WORK:[issues]` | Changes needed |
