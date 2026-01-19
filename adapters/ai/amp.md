# Amp Adapter

## Invocation

```bash
# Single command
echo "Read .mothership/mothership.md and run: build" | amp

# With all permissions (for autonomous work)
echo "Read .mothership/mothership.md and run: build" | amp --dangerously-allow-all
```

## Loop Script

```bash
./mothership.sh build 20
```

## Handoff (for long tasks)

Add to `~/.config/amp/settings.json`:
```json
{
  "auto_handoff": true
}
```

This enables automatic handoff when context fills up.

## MCP Tools Available

Amp has built-in MCP tools:
- `Linear:*` - Linear integration
- File operations
- Git operations
- Terminal access

## Tips

- Amp auto-reads AGENTS.md files
- Use `amp --continue` to resume threads
- Check `amp threads` for history
