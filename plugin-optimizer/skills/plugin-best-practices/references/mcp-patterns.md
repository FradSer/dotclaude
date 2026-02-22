# MCP Integration Patterns

Best practices for integrating Model Context Protocol servers in plugins.

## Configuration Options

### Standalone .mcp.json (Recommended)
```json
{
  "server-name": {
    "type": "stdio|http|sse",
    "command": "executable",
    "args": ["arg1", "arg2"],
    "env": {
      "VAR": "${ENV_VAR}"
    }
  }
}
```

### Embedded in plugin.json
```json
{
  "name": "plugin-name",
  "mcpServers": {
    "server-name": {
      "type": "stdio",
      "command": "executable"
    }
  }
}
```

## Transport Types

### stdio - Local CLI Tools
Best for: git, docker, npm, local scripts

```json
{
  "github": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-github"],
    "env": {
      "GITHUB_TOKEN": "${GITHUB_TOKEN}"
    }
  }
}
```

### http - Remote APIs
Best for: SaaS services, cloud APIs

```json
{
  "api-service": {
    "type": "http",
    "url": "https://api.example.com/mcp",
    "headers": {
      "Authorization": "Bearer ${API_TOKEN}"
    }
  }
}
```

### sse - Real-time Streaming
Best for: monitoring, live updates

```json
{
  "monitoring": {
    "type": "sse",
    "url": "https://monitor.example.com/stream",
    "headers": {
      "X-API-Key": "${MONITOR_KEY}"
    }
  }
}
```

## Common Integration Patterns

### NPM Package
```json
{
  "package-server": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@company/mcp-server"],
    "env": {"API_KEY": "${API_KEY}"}
  }
}
```

### Database
```json
{
  "database": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@example/db-server"],
    "env": {"DATABASE_URL": "${DATABASE_URL}"}
  }
}
```

### Local Binary
```json
{
  "custom-server": {
    "type": "stdio",
    "command": "./bin/mcp-server",
    "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"]
  }
}
```

## Best Practices

### Security
- **Never hardcode secrets** - always use `${ENV_VAR}` syntax
- Use minimal permission scopes for tokens
- Document required environment variables in README
- Provide `.env.example` template

### Environment Variables
```json
{
  "database": {
    "type": "http",
    "url": "${DB_URL}",
    "headers": {
      "Authorization": "Bearer ${DB_TOKEN}",
      "X-Project": "${PROJECT_ID}"
    }
  }
}
```

### Development
- Test stdio locally before deploying http/sse
- Use `.env.example` to document required vars
- Test MCP integration independently
- Provide clear error messages

### Performance
- Use http for remote services (avoids process overhead)
- Set reasonable timeouts
- Implement caching where appropriate
- Clean up resources on shutdown

## Validation Checklist

**Configuration:**
- [ ] Valid JSON syntax
- [ ] Required fields present (type, command/url)
- [ ] Transport type: stdio, http, or sse
- [ ] Server names use kebab-case

**Security:**
- [ ] No hardcoded secrets/API keys
- [ ] All credentials use ${ENV_VAR}
- [ ] Environment variables documented
- [ ] .env.example provided

**Functionality:**
- [ ] Server executable/URL accessible
- [ ] Required env vars available
- [ ] Transport matches server capabilities
- [ ] Headers/auth properly configured

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Server not found | Verify command in PATH, check network for npx |
| Auth failures | Check env vars set, verify token permissions |
| Timeouts | Verify URL accessible, check firewall |
| Invalid config | Validate JSON, ensure required fields present |

## MCP Tool Invocation in Claude Code

### Tool Naming Convention

MCP tools follow the naming pattern `mcp__<server-name>__<tool-name>`:

```
mcp__my-server__get_data
mcp__api-client__fetch
mcp__docs-server__*        // Wildcard for all tools from a server
```

### Authorization

MCP tools require explicit permission before use. Configure `allowedTools`:

```typescript
// In Claude Agent SDK or similar
options: {
  mcpServers: {
    "my-server": {
      command: "npx",
      args: ["-y", "@company/mcp-server"]
    }
  },
  allowedTools: ["mcp__my-server__*"]  // Allow all tools from server
}
```

### Usage Patterns

**Implicit invocation (recommended)**: Describe intent in natural language
```
"Retrieve the current data from the server"
"List items from the API"
"Query the database for user records"
```

**Explicit invocation**: Direct tool specification (rare)
Claude automatically identifies and calls the appropriate MCP tool.

### Debugging MCP Calls

Log MCP tool invocations in agent code:

```typescript
if (message.type === "assistant") {
  for (const block of message.content) {
    if (block.type === "tool_use" && block.name.startsWith("mcp__")) {
      console.log(`MCP tool called: ${block.name}`);
    }
  }
}
```

### Summary

- Claude Code automatically loads MCP tool definitions into context
- Use natural language requests to trigger MCP tool calls
- Tool naming follows `mcp__server__tool` format
- Authorize tools via `allowedTools` configuration
