# Next.js DevTools Plugin

Next.js development tools integration via MCP server — runtime diagnostics, development automation, and documentation access for coding agents.

**Version**: 0.1.0

**Total capabilities**: 7 Tools + 2 Prompts + 17 Resources = 26 available features.

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

### MCP Prompts (2)

| Prompt | Purpose |
|--------|---------|
| `upgrade-nextjs-16` | Complete Next.js 16 upgrade with codemod execution and manual fixes |
| `enable-cache-components` | Complete Cache Components setup with automated error fixing |

### MCP Resources (17)

**Cache Components (13):**
- `cache-components://overview` - Critical errors AI agents make, quick reference
- `cache-components://core-mechanics` - Fundamental paradigm shift and cacheComponents behavior
- `cache-components://public-caches` - Public cache mechanics using 'use cache'
- `cache-components://private-caches` - Private cache mechanics using 'use cache: private'
- `cache-components://runtime-prefetching` - Prefetch configuration and stale time rules
- `cache-components://request-apis` - Async params, searchParams, cookies(), headers() patterns
- `cache-components://cache-invalidation` - updateTag(), revalidateTag() patterns and strategies
- `cache-components://advanced-patterns` - cacheLife(), cacheTag(), draft mode
- `cache-components://build-behavior` - What gets prerendered, static shells, build-time behavior
- `cache-components://error-patterns` - Common errors and solutions for Cache Components
- `cache-components://test-patterns` - Real test-driven patterns from 125+ fixtures
- `cache-components://reference` - Mental models, API reference, and checklists
- `cache-components://route-handlers` - Using 'use cache' in Route Handlers (API Routes)

**Other (4):**
- `nextjs-fundamentals://use-client` - Learn when and why to use 'use client' in Server Components
- `nextjs16://migration/beta-to-stable` - Complete guide for migrating from Next.js 16 beta to stable
- `nextjs16://migration/examples` - Real-world examples of migrating to Next.js 16
- `nextjs-docs://llms-index` - Complete Next.js documentation index

## Troubleshooting

**MCP server not connecting**: Verify Next.js v16+, ensure `next-devtools-mcp` is in `.mcp.json`, and restart the dev server.

**"No server info found"**: Dev server must be running (`npm run dev`). Use `upgrade_nextjs_16` if on Next.js 15 or earlier.

**`nextjs_index` auto-discovery fails**: Specify the port explicitly — tell Claude which port your dev server is running on.

**Module not found error**: Clear the npx cache and restart the MCP client.

## Author

Frad LEE (fradser@gmail.com)

## License

MIT
