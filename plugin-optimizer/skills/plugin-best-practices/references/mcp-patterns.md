# MCP Integration Patterns

Best practices for integrating Model Context Protocol servers in plugins.

**Official Documentation**: https://code.claude.com/docs/en/mcp

## Overview

MCP (Model Context Protocol) connects Claude Code to external tools and services. Plugins can bundle MCP servers for automatic setup.

## Configuration Locations

| Location | Format | Use Case |
|----------|--------|----------|
| `.mcp.json` at plugin root | Separate file | Recommended - better organization |
| Inline in `plugin.json` | `mcpServers` key | Simple setups |

## Transport Types

| Transport | Best For | Configuration Fields |
|-----------|----------|---------------------|
| **http** | Remote cloud services, APIs | `url`, `headers` |
| **sse** | Real-time streaming, live updates | `url`, `headers` |
| **stdio** | Local CLI tools, package managers | `command`, `args`, `env` |

## Configuration Examples

### HTTP Server (Remote API)

```json
{
  "api-service": {
    "type": "http",
    "url": "https://api.example.com/mcp"
  }
}
```

### HTTP with Authentication

```json
{
  "secure-api": {
    "type": "http",
    "url": "${API_BASE_URL}/mcp",
    "headers": {
      "Authorization": "Bearer ${API_TOKEN}"
    }
  }
}
```

### SSE Server (Streaming)

```json
{
  "streaming-service": {
    "type": "sse",
    "url": "https://stream.example.com/sse",
    "headers": {
      "X-API-Key": "${API_KEY}"
    }
  }
}
```

### stdio Server (Package Manager)

```json
{
  "tool-server": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@org/mcp-server"],
    "env": {
      "API_KEY": "${API_KEY}"
    }
  }
}
```

### stdio Server (Plugin Binary)

```json
{
  "custom-server": {
    "type": "stdio",
    "command": "${CLAUDE_PLUGIN_ROOT}/bin/mcp-server",
    "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"]
  }
}
```

## Environment Variable Expansion

Supported syntax:

- `${VAR}` - Expand environment variable
- `${VAR:-default}` - Expand with fallback default
- `${CLAUDE_PLUGIN_ROOT}` - Plugin root directory (for plugin MCP servers)

Expansion works in: `command`, `args`, `env`, `url`, `headers`

## Using MCP in Skill Content

### Key Principle

**Always use natural language to describe intent.** Claude automatically selects the appropriate MCP tool.

**Never reference internal MCP tool names** (`mcp__server__tool`) in skill content.

### Correct Patterns

```markdown
Query the data source for records matching the criteria
Search the external service for items
Fetch data from the API
Check the monitoring system for alerts
Create a draft in the external system
```

### Wrong Patterns

```markdown
Call mcp__server__tool_name to get data
Use mcp__service__function to find items
Execute mcp__api__endpoint
```

### When MCP Tools Are Available

- User has configured MCP servers (via `claude mcp add` or `.mcp.json`)
- Plugin bundles MCP servers
- Servers are enabled and running

Check available servers: `/mcp`

## Security Best Practices

- **Never hardcode secrets** - always use `${ENV_VAR}` syntax
- Use minimal permission scopes for tokens
- Document required environment variables in README
- Provide `.env.example` template

## Plugin MCP Features

- **Automatic lifecycle**: Servers start when plugin enables (restart required to apply changes)
- **Tools appear alongside** manually configured MCP tools
- **View all servers** with `/mcp` command

## Validation Checklist

**Configuration:**

- [ ] Valid JSON syntax
- [ ] Required fields present (`type`, and `command` for stdio or `url` for http/sse)
- [ ] Transport type: stdio, http, or sse
- [ ] Server names use kebab-case

**Security:**

- [ ] No hardcoded secrets/API keys
- [ ] All credentials use `${ENV_VAR}`
- [ ] Environment variables documented

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Server not found | Verify command in PATH, check network connectivity |
| Auth failures | Check env vars set, verify token permissions |
| Timeouts | Verify URL accessible, check firewall |
| Invalid config | Validate JSON, ensure required fields present |
| Changes not applied | Restart Claude Code to apply MCP server changes |

## Summary

**Configuration**:
- Use `.mcp.json` at plugin root (recommended) or inline in `plugin.json`
- Support stdio, HTTP, and SSE transports
- Use `${CLAUDE_PLUGIN_ROOT}` for plugin-relative paths
- Use `${VAR}` and `${VAR:-default}` for environment variables

**Skill Content**:
- Use natural language to describe intent - Claude auto-selects MCP tools
- Never reference internal tool names (`mcp__server__tool`)

**Official Documentation**: https://code.claude.com/docs/en/mcp
