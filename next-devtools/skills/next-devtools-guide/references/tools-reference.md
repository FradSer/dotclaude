# Next.js DevTools MCP Tools Reference

**Total capabilities**: 7 Tools + 2 Prompts + 17 Resources = 26 available features.

## MCP Tools (7)

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

## MCP Prompts (2)

| Prompt | Purpose | When to Use |
|--------|---------|-------------|
| `upgrade-nextjs-16` | Complete Next.js 16 upgrade with codemod execution and manual fixes | Upgrading from Next.js 15 or earlier |
| `enable-cache-components` | Complete Cache Components setup with automated error fixing | Migrating to Next.js 16 Cache Components |

## MCP Resources (19)

### Cache Components Resources (13)

| URI | Purpose |
|-----|---------|
| `cache-components://overview` | Critical errors AI agents make, quick reference for Cache Components |
| `cache-components://core-mechanics` | Fundamental paradigm shift and cacheComponents behavior |
| `cache-components://public-caches` | Public cache mechanics using 'use cache' |
| `cache-components://private-caches` | Private cache mechanics using 'use cache: private' |
| `cache-components://runtime-prefetching` | Prefetch configuration and stale time rules |
| `cache-components://request-apis` | Async params, searchParams, cookies(), headers() patterns |
| `cache-components://cache-invalidation` | updateTag(), revalidateTag() patterns and cache invalidation strategies |
| `cache-components://advanced-patterns` | cacheLife(), cacheTag(), draft mode and advanced caching strategies |
| `cache-components://build-behavior` | What gets prerendered, static shells, and build-time behavior |
| `cache-components://error-patterns` | Common errors and solutions for Cache Components |
| `cache-components://test-patterns` | Real test-driven patterns from 125+ fixtures |
| `cache-components://reference` | Mental models, API reference, and checklists for Cache Components |
| `cache-components://route-handlers` | Using 'use cache' directive in Route Handlers (API Routes) |

### Other Resources (4)

| URI | Purpose |
|-----|---------|
| `nextjs-fundamentals://use-client` | Learn when and why to use 'use client' in Server Components |
| `nextjs16://migration/beta-to-stable` | Complete guide for migrating from Next.js 16 beta to stable release |
| `nextjs16://migration/examples` | Real-world examples of migrating to Next.js 16 |
| `nextjs-docs://llms-index` | Complete Next.js documentation index from nextjs.org/docs/llms.txt |

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
