# Next.js DevTools Plugin

Next.js development tools integration via MCP server — runtime diagnostics, development automation, and documentation access for coding agents.

**Version**: 0.1.0

## Installation

```bash
claude plugin install next-devtools@frad-dotclaude
```

## Overview

This plugin wires Claude to the `next-devtools-mcp` bridge server, giving it direct access to your running Next.js dev server. With Next.js 16+, Claude can inspect live errors, routes, Server Actions, and component metadata without guessing from static files.

Three primary capabilities:

- **Runtime diagnostics** (Next.js 16+): query live errors, routes, logs, and Server Action metadata from the built-in `/_next/mcp` endpoint
- **Development automation**: upgrade to Next.js 16, set up Cache Components, and run browser tests via Playwright
- **Documentation access**: search official Next.js docs through a curated knowledge base

## Requirements

- Node.js v20.19 or newer
- npm or pnpm
- Next.js 16+ for runtime diagnostics (all versions for automation and docs)

## MCP Server

The plugin registers the `next-devtools` MCP server with stdio transport:

```json
{
  "mcpServers": {
    "next-devtools": {
      "command": "npx",
      "args": ["-y", "next-devtools-mcp@latest"]
    }
  }
}
```

All MCP tools follow the naming pattern `mcp__plugin_next-devtools_next-devtools__<tool-name>`.

## Skills

### `next-devtools-guide` (Internal)

Guides Claude on tool selection, session initialization, and common workflows. Automatically loaded — not user-invocable. Claude uses it to know when to call `init`, `nextjs_index`, `nextjs_call`, `nextjs_docs`, `browser_eval`, and the automation tools.

For the full tools table and `nextjs_call` tool names, see [skills/next-devtools-guide/references/tools-reference.md](skills/next-devtools-guide/references/tools-reference.md).

## Quick Start

Start your Next.js 16+ dev server, then ask Claude to inspect your app:

```
Show me all current build errors in my Next.js app
List all routes in this project
Trace the Server Action with ID <id> to its source file
Search the Next.js docs for cache components
```

Claude will call `init`, discover the running server via `nextjs_index`, then use `nextjs_call` with the appropriate tool.

### MCP Tool Reference

| Tool | Purpose |
|------|---------|
| `init` | Initialize MCP context (call at session start) |
| `nextjs_index` | Discover running Next.js dev servers |
| `nextjs_call` | Execute a specific tool on the dev server |
| `nextjs_docs` | Fetch official Next.js documentation |
| `browser_eval` | Playwright browser automation |
| `enable_cache_components` | Migrate to Cache Components |
| `upgrade_nextjs_16` | Upgrade from Next.js 15 or earlier |

## Troubleshooting

**MCP server not connecting**: Verify Next.js v16+, ensure `next-devtools-mcp` is in `.mcp.json`, and restart the dev server.

**"No server info found"**: Dev server must be running (`npm run dev`). Use `upgrade_nextjs_16` if on Next.js 15 or earlier.

**`nextjs_index` auto-discovery fails**: Specify the port explicitly — tell Claude which port your dev server is running on.

**Module not found error**: Clear the npx cache and restart the MCP client.

## Author

Frad LEE (fradser@gmail.com)

## License

MIT
