---
globs:
  - "src/**"
---

# Wiring Validation Rules

- No empty handlers: `onClick={}`, `onSubmit={}`, `() => {}` are forbidden
- All event handlers must call real functions with real implementations
- All forms must submit to real API endpoints — no placeholder URLs
- All links must point to real routes — no `href="#"`
- Run `scripts/check-wiring.sh` after creating or modifying UI components
- Every button, form, and interactive element must be wired to working logic
