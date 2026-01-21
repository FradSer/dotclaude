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

### GitHub
```json
{
  "github": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-github"],
    "env": {"GITHUB_TOKEN": "${GITHUB_TOKEN}"}
  }
}
```

### Database
```json
{
  "postgres": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-postgres"],
    "env": {"POSTGRES_URL": "${DATABASE_URL}"}
  }
}
```

### Kubernetes
```json
{
  "kubectl": {
    "type": "stdio",
    "command": "mcp-kubectl-wrapper",
    "args": ["--namespace", "${K8S_NAMESPACE}"],
    "env": {"KUBECONFIG": "${KUBECONFIG_PATH}"}
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
