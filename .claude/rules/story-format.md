---
globs:
  - "**stories**"
  - "**story**"
  - "**plan**"
  - ".mothership/stories.json"
---

# Story Format Rules

- Title format: "User can [verb] [noun]"
- Every AC must be atomic and pass/fail testable
- Every AC must have a `verify` step explaining how to confirm it works
- Story types: ui | api | database | integration | fullstack
- One component/route/function per story — no multi-deliverable stories
- Include expected file paths in every story
- Include type-specific verification scripts
- Stories should be independent — minimize cross-story dependencies
- Size: ~15-20 minutes to implement
