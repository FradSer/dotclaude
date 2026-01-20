# MCP Integration Patterns

Model Context Protocol (MCP) enables plugins to connect external tools, databases, APIs, and services to Claude Code.

## Purpose

MCP integration allows plugins to:
- Connect to external APIs and cloud services
- Access databases and data sources
- Integrate development tools and CLIs
- Provide domain-specific functionality from external systems

## Configuration Locations

### Option 1: Standalone .mcp.json (Recommended)

Place `.mcp.json` in the plugin root directory for clear separation of MCP configuration.

**Structure:**
```json
{
  "server-name": {
    "type": "stdio|http|sse",
    "command": "executable",
    "args": ["arg1", "arg2"],
    "env": {
      "VAR_NAME": "${ENV_VAR}"
    }
  }
}
```

### Option 2: Embedded in plugin.json

Add `mcpServers` object to `.claude-plugin/plugin.json` for consolidated configuration.

**Structure:**
```json
{
  "name": "plugin-name",
  "description": "Plugin description",
  "mcpServers": {
    "server-name": {
      "type": "stdio",
      "command": "executable",
      "args": ["arg1", "arg2"]
    }
  }
}
```

## Transport Types

### stdio (Standard I/O)

Best for local scripts, CLI tools, and system integrations.

**Characteristics:**
- Process spawned locally
- Communication via stdin/stdout
- Most common for development tools
- Suitable for git, docker, npm, etc.

**Example:**
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

### http (HTTP REST)

Best for remote APIs and cloud services.

**Characteristics:**
- Remote server communication
- RESTful endpoints
- Supports authentication headers
- Ideal for SaaS integrations

**Example:**
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

### sse (Server-Sent Events)

Best for real-time streaming and updates.

**Characteristics:**
- One-way server-to-client streaming
- Real-time notifications
- Long-lived connections
- Suitable for monitoring and alerts

**Example:**
```json
{
  "monitoring": {
    "type": "sse",
    "url": "https://monitor.example.com/stream",
    "headers": {
      "X-API-Key": "${MONITOR_API_KEY}"
    }
  }
}
```

## Configuration Scopes

MCP servers can be configured at different scopes:

### Plugin Scope (Recommended for Plugins)

**File:** `.mcp.json` or `plugin.json` in plugin directory
**Visibility:** Available when plugin is active
**Use case:** Plugin-specific integrations

### Project Scope

**File:** `.claude/.mcp.json` in project root
**Visibility:** All sessions in this project
**Use case:** Project-specific tools and databases

### User Scope

**File:** `~/.claude/.mcp.json`
**Visibility:** All projects for this user
**Use case:** Personal API keys and global tools

## Environment Variables

Use environment variable substitution for sensitive data and configuration.

**Pattern:** `${VARIABLE_NAME}`

**Example:**
```json
{
  "database": {
    "type": "http",
    "url": "${DB_API_URL}",
    "headers": {
      "Authorization": "Bearer ${DB_API_TOKEN}",
      "X-Project-ID": "${PROJECT_ID}"
    }
  }
}
```

**Best Practices:**
- Never hardcode API keys or secrets
- Use ${ENV_VAR} syntax for all credentials
- Document required environment variables in README
- Provide .env.example template for users

## Common Integration Patterns

### GitHub Integration

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

**Required:** `GITHUB_TOKEN` environment variable
**Capabilities:** Repository access, issues, PRs, code search

### Database Access

```json
{
  "postgres": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-postgres"],
    "env": {
      "POSTGRES_URL": "${DATABASE_URL}"
    }
  }
}
```

**Required:** `DATABASE_URL` environment variable
**Capabilities:** Query execution, schema inspection, data access

### Custom API Service

```json
{
  "internal-api": {
    "type": "http",
    "url": "${INTERNAL_API_BASE_URL}/mcp",
    "headers": {
      "Authorization": "Bearer ${INTERNAL_API_TOKEN}",
      "X-Team-ID": "${TEAM_ID}"
    }
  }
}
```

**Required:** `INTERNAL_API_BASE_URL`, `INTERNAL_API_TOKEN`, `TEAM_ID`
**Capabilities:** Custom business logic, internal tools

### Local CLI Tool

```json
{
  "kubectl": {
    "type": "stdio",
    "command": "mcp-kubectl-wrapper",
    "args": ["--namespace", "${K8S_NAMESPACE}"],
    "env": {
      "KUBECONFIG": "${KUBECONFIG_PATH}"
    }
  }
}
```

**Required:** `K8S_NAMESPACE`, `KUBECONFIG_PATH`
**Capabilities:** Kubernetes cluster management

## Validation Checklist

**Configuration Structure:**
- [ ] Valid JSON syntax in .mcp.json
- [ ] Required fields present (type, command/url)
- [ ] Transport type is one of: stdio, http, sse
- [ ] Server names use kebab-case

**Security:**
- [ ] No hardcoded secrets or API keys
- [ ] All credentials use ${ENV_VAR} syntax
- [ ] Environment variables documented in README
- [ ] .env.example provided for required variables

**Documentation:**
- [ ] README explains MCP integration purpose
- [ ] Required environment variables listed
- [ ] Setup instructions included
- [ ] Example .env.example file provided

**Functionality:**
- [ ] Server executable/URL is accessible
- [ ] Required environment variables are available
- [ ] Transport type matches server capabilities
- [ ] Headers/auth properly configured

## Common Issues

**Issue:** Server not found or command fails
**Fix:** Verify command is installed and in PATH. For npx commands, ensure network access.

**Issue:** Authentication failures
**Fix:** Check environment variables are set correctly. Verify token/key permissions.

**Issue:** Server communication timeout
**Fix:** Verify URL is accessible. Check network/firewall settings. For stdio, ensure command completes.

**Issue:** Invalid configuration error
**Fix:** Validate JSON syntax. Ensure required fields (type, command/url) are present.

## Best Practices

**Development:**
- Start with stdio for local testing before deploying http/sse
- Use .env.example to document all required environment variables
- Test MCP integration independently before plugin integration
- Provide clear error messages for missing configuration

**Security:**
- Never commit .env files with actual credentials
- Use minimal permission scopes for API tokens
- Validate and sanitize all inputs from MCP servers
- Document security requirements in README

**Performance:**
- Use http for remote services to avoid process overhead
- Implement caching where appropriate
- Set reasonable timeouts for network requests
- Clean up resources properly on server shutdown

**Maintenance:**
- Pin MCP server versions for reproducibility
- Document version compatibility requirements
- Provide upgrade guides for breaking changes
- Monitor deprecation notices from MCP providers
