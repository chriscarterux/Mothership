# Cursor Adapter

## Chat Mode

In Cursor's AI chat:
```
@.mothership/mothership.md Run: build
```

Or:
```
Read the file .mothership/mothership.md and execute: plan user authentication
```

## Composer Mode

For larger changes, use Composer:
1. Open Composer (Cmd+I / Ctrl+I)
2. Reference: `@.mothership/mothership.md`
3. Command: "Run: build"

## Agent Mode

If Cursor Agent is enabled:
```
@agent Read .mothership/mothership.md and run: build
```

## Tips

- Use `@codebase` for full context
- Cursor has built-in terminal access
- Can reference multiple files: `@file1 @file2`
- Use "Apply" to execute suggested changes

## Loop

Cursor doesn't have a CLI loop. Options:
1. Run manually in chat
2. Use Cursor's API (if available)
3. Combine with external script that calls Cursor
