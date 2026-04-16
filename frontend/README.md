# frontend

Web frontend development toolkit combining shadcn/ui component management and Next.js development tools.

## Skills

### shadcn (synced from upstream)

Manages shadcn/ui components and projects -- adding, searching, fixing, debugging, styling, and composing UI. Provides project context, component docs, and usage examples.

- **Source**: [shadcn-ui/ui](https://github.com/shadcn-ui/ui/tree/main/skills/shadcn)
- **Sync**: `./scripts/sync-shadcn.sh`

### next-devtools-guide

Next.js development tools integration via MCP server. Runtime diagnostics, development automation, and documentation access.

- **MCP Server**: `next-devtools-mcp`
- **Capabilities**: 7 Tools + 2 Prompts + 17 Resources

## Syncing

The shadcn skill is synced from the official [shadcn-ui/ui](https://github.com/shadcn-ui/ui) repository:

```bash
# Check for updates
./scripts/sync-shadcn.sh --check

# Sync latest
./scripts/sync-shadcn.sh

# Force sync (skip confirmation)
./scripts/sync-shadcn.sh --force
```

## License

MIT
