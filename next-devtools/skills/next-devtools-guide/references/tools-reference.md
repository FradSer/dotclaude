# Next.js DevTools MCP Tools Reference

## MCP Tools

All tools follow the naming pattern `mcp__plugin_next-devtools_next-devtools__<tool-name>`:

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `init` | Initialize MCP context | At start of each session |
| `nextjs_index` | Discover running Next.js dev servers | Before implementing changes or diagnostics |
| `nextjs_call` | Call a specific Next.js MCP tool | After discovering tools with `nextjs_index` |
| `nextjs_docs` | Fetch Next.js documentation | After getting path from `nextjs-docs://llms-index` resource |
| `browser_eval` | Playwright browser automation | Testing pages requiring actual rendering |
| `enable_cache_components` | Cache Components setup and migration | Migrating to Next.js 16 Cache Components |
| `upgrade_nextjs_16` | Guide through upgrade to Next.js 16 | Upgrading from Next.js 15 or earlier |

## Common nextjs_call Tool Names

After discovering servers with `nextjs_index`, use `nextjs_call` with these `toolName` values:

| Tool Name | Purpose |
|-----------|---------|
| `get_errors` | Retrieve build, runtime, and type errors |
| `get_routes` | List all application routes |
| `get_logs` | Access development server log file path |
| `get_page_metadata` | Get page route, component, and rendering details |
| `get_project_metadata` | Get project structure and configuration |
| `get_server_action_by_id` | Trace Server Action to source file |

## Architecture

```
Coding Agent
      ↓
next-devtools-mcp (bridge server)
      ↓
      ├─→ Next.js Dev Server MCP Endpoint (/_next/mcp) ← Runtime diagnostics
      ├─→ Playwright MCP Server ← Browser automation
      └─→ Knowledge Base & Tools ← Documentation, upgrades, setup automation
```

For Next.js 16+ projects, the server auto-discovers the running dev server's MCP endpoint at `/_next/mcp`.

For all Next.js projects, development automation tools and documentation access work independently of the runtime connection.

See the [next-devtools-mcp repository](https://github.com/vercel/next-devtools-mcp) for complete documentation.
