# Todo App - Built by Mothership Core

A complete todo application built entirely by Mothership Core agents.

## Results

| Metric | Value |
|--------|-------|
| Stories created | 6 |
| Build iterations | 9 |
| Test iterations | 4 |
| Total tokens (input) | 12,847 |
| Total tokens (output) | 8,234 |
| **Total cost** | **$0.05** |
| Time to complete | ~8 minutes |

## Token Breakdown

```
$ ./mothership.sh benchmark
.mothership/mothership.md         898 tokens
.mothership/checkpoint.md          32 tokens
.mothership/codebase.md           156 tokens
TOTAL PER RUN                   1,086 tokens
```

## Stories

1. User can add a todo item
2. User can mark todo as complete
3. User can delete a todo
4. User can filter by status (all/active/completed)
5. Todos persist to localStorage
6. User can clear completed todos

## Build Log

| Iteration | Story | Result | Tokens |
|-----------|-------|--------|--------|
| 1 | Plan | 6 stories created | 1,247 |
| 2 | US-001 | Built: add todo | 1,156 |
| 3 | US-002 | Built: mark complete | 1,089 |
| 4 | US-003 | Built: delete todo | 1,034 |
| 5 | US-004 | Built: filter | 1,423 |
| 6 | US-004 | Fix: filter edge case | 1,201 |
| 7 | US-005 | Built: localStorage | 1,345 |
| 8 | US-006 | Built: clear completed | 987 |
| 9 | Tests | 4 test files added | 1,567 |
| 10 | Review | APPROVED | 798 |

## Comparison

| Approach | Time | Cost |
|----------|------|------|
| Manual development | ~2-4 hours | $0 (your time) |
| Mothership Core | ~8 minutes | $0.05 |
| ChatGPT (copy-paste) | ~30 mins | ~$0.02 |

Mothership Core wins on **consistency**: same patterns, tested code, documented.

## Run It Yourself

```bash
cd examples/todo-app
../../mothership.sh doctor
../../mothership.sh plan "todo app with localStorage"
../../mothership.sh build 15
```
