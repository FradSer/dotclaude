---
name: next-devtools-guide
description: This skill should be used when working with Next.js projects that have the next-devtools MCP server configured, when encountering MCP connection issues, or when needing guidance on which MCP tool to use for specific tasks such as error detection, route inspection, Server Action tracing, or Cache Components migration.
user-invocable: false
---

# Next.js DevTools MCP

**Requirements**: Node.js v20.19+, npm or pnpm, Next.js 16+ for runtime diagnostics.

**Tool naming**: All tools follow `mcp__plugin_next-devtools_next-devtools__<tool-name>`. This file uses abbreviated names for brevity.

See `references/tools-reference.md` for the complete tools table and `nextjs_call` tool names.

## Session Initialization

Call `init` at the start of every session to establish documentation-first behavior and tool usage guidance.

## Quick Start

**Next.js 16+ (runtime diagnostics):**

1. Start the dev server: `npm run dev` (or `pnpm dev`)
2. Call `init` to initialize MCP context
3. Call `nextjs_index` to discover the running server and available tools
4. Call `nextjs_call` with the desired `toolName` to execute tools on the dev server

**All Next.js versions (automation and docs):**

After `init`, use `upgrade_nextjs_16`, `enable_cache_components`, `nextjs_docs`, or `browser_eval` as needed.

## Common Workflows

**Before implementing changes**: Call `nextjs_index` to understand current application state, then `nextjs_call` with the appropriate tool.

**Error detection**: Call `nextjs_index`, then `nextjs_call` with `toolName="get_errors"`.

**Route inspection**: Call `nextjs_index`, then `nextjs_call` with `toolName="get_routes"`.

**Server Action tracing**: Call `nextjs_call` with `toolName="get_server_action_by_id"` and appropriate args.

**Documentation search**: Read the `nextjs-docs://llms-index` MCP resource to get the correct path, then call `nextjs_docs` with that path.

**Important**: The `args` parameter for `nextjs_call` MUST be an object. Omit `args` entirely if the tool takes no arguments.

## Troubleshooting

**MCP server not connecting:**

- Verify Next.js v16+
- Confirm `next-devtools-mcp` is configured in `.mcp.json`
- Start or restart the dev server (`npm run dev`)
- If `nextjs_index` auto-discovery fails, ask the user which port their dev server is running on and pass it as the `port` parameter

**"No server info found"**: Dev server must be running. Use the `upgrade_nextjs_16` tool if on Next.js 15 or earlier.

**Module not found**: Clear the npx cache and restart the MCP client.

## Best Practices

- Call `init` at session start before using other tools
- Start the dev server before using `nextjs_index` or `nextjs_call`
- Prefer `nextjs_index`/`nextjs_call` over `browser_eval` for error detection and diagnostics
- Use `browser_eval` only for tasks requiring actual page rendering or JavaScript execution
- Read `nextjs-docs://llms-index` resource first before calling `nextjs_docs`
