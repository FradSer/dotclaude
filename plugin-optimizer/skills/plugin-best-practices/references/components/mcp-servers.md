# MCP Servers Component Reference

Plugins can bundle Model Context Protocol (MCP) servers to connect Claude Code with external tools and services.

**Official Documentation**: https://code.claude.com/docs/en/mcp

**Location**: `.mcp.json` in plugin root, or inline in `plugin.json`

## Configuration Options

### Standalone .mcp.json (Recommended)

Place at plugin root for better organization:

```json
{
  "server-name": {
    "command": "${CLAUDE_PLUGIN_ROOT}/servers/server-binary",
    "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
    "env": {
      "API_URL": "${API_URL}"
    }
  }
}
```

### Embedded in plugin.json

Inline configuration for simple setups:

```json
{
  "name": "my-plugin",
  "mcpServers": {
    "plugin-api": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/api-server",
      "args": ["--port", "8080"]
    }
  }
}
```

## Transport Types

### stdio - Local Processes

Best for: CLI tools, local scripts, package managers

```json
{
  "local-tool": {
    "command": "npx",
    "args": ["-y", "@org/mcp-server"],
    "env": {
      "API_KEY": "${API_KEY}"
    }
  }
}
```

### http - Remote HTTP Servers

Best for: Remote APIs, cloud services (most widely supported)

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

### sse - Server-Sent Events

Best for: Real-time streaming, live updates

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

## Plugin MCP Features

- **Automatic lifecycle**: Servers start when plugin enables (requires Claude Code restart to apply changes)
- **Environment variables**: Use `${CLAUDE_PLUGIN_ROOT}` for plugin-relative paths
- **User environment access**: Same environment variables as manually configured servers
- **Multiple transport types**: Support stdio, SSE, and HTTP transports

## Environment Variable Expansion

Supported syntax in `.mcp.json`:

- `${VAR}` - Expands to the value of environment variable `VAR`
- `${VAR:-default}` - Expands to `VAR` if set, otherwise uses `default`

Expansion locations:

- `command` - The server executable path
- `args` - Command-line arguments
- `env` - Environment variables passed to the server
- `url` - For HTTP server types
- `headers` - For HTTP server authentication

Example:

```json
{
  "api-server": {
    "type": "http",
    "url": "${API_BASE_URL:-https://api.example.com}/mcp",
    "headers": {
      "Authorization": "Bearer ${API_KEY}"
    }
  }
}
```

## Viewing Plugin MCP Servers

```
/mcp
```

Plugin servers appear in the list with indicators showing they come from plugins.

## Benefits of Plugin MCP Servers

- **Bundled distribution**: Tools and servers packaged together
- **Automatic setup**: No manual MCP configuration needed
- **Team consistency**: Everyone gets the same tools when plugin is installed
