# Manifest Patterns

Complete guide to plugin.json and marketplace.json manifest patterns for Claude Code plugins.

## Plugin Manifest Patterns (plugin.json)

**Location:** `.claude-plugin/plugin.json`

### Core Pattern (Minimal - Recommended)

```json
{
  "name": "plugin-name",
  "description": "Brief description of what the plugin does",
  "author": {
    "name": "Author Name",
    "email": "author@example.com"
  }
}
```

### Required Fields

- `name`: Plugin identifier (kebab-case, matches directory name)
- `description`: One-line summary of plugin functionality
- `author`: Object with at least `name` field

### Optional Fields

- `version`: Semantic version string (e.g., "0.1.0", "1.2.3")
- `author.email`: Author email address
- `author.url`: Author website URL
- `homepage`: Plugin homepage/documentation URL
- `repository`: Repository URL (GitHub, GitLab, etc.)
- `license`: License identifier (e.g., "MIT", "Apache-2.0")
- `keywords`: Array of searchable keywords (e.g., `["git", "automation", "workflow"]`)

### Key Insights

- **Keep it minimal**: Official plugins intentionally use minimal manifests - rely on auto-discovery
- **Auto-discovery works**: Claude automatically discovers `commands/`, `agents/`, `skills/`, and `hooks/` directories
- **No component listing**: Do not manually list commands, agents, or skills in `plugin.json`
- **External plugins may be verbose**: Third-party plugins (like Stripe) may include more metadata for marketplace visibility

### Examples from Official Plugins

**Minimal (most common pattern):**

```json
{
  "name": "code-review",
  "description": "Automated code review for pull requests using multiple specialized agents",
  "author": {
    "name": "Anthropic",
    "email": "support@anthropic.com"
  }
}
```

**With version and homepage:**

```json
{
  "name": "stripe",
  "description": "Stripe development plugin for Claude",
  "version": "0.1.0",
  "author": {
    "name": "Stripe",
    "url": "https://stripe.com"
  },
  "homepage": "https://docs.stripe.com",
  "repository": "https://github.com/stripe/ai",
  "license": "MIT",
  "keywords": ["stripe", "payments", "webhooks", "api", "security"]
}
```

## Marketplace Manifest Patterns (marketplace.json)

**Location:** `.claude-plugin/marketplace.json`

### Core Pattern

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "marketplace-name",
  "description": "Description of the plugin marketplace",
  "owner": {
    "name": "Owner Name",
    "email": "owner@example.com"
  },
  "plugins": [
    {
      "name": "plugin-name",
      "description": "Plugin description",
      "source": "./plugin-directory",
      "version": "0.1.0",
      "author": {
        "name": "Author Name",
        "email": "author@example.com"
      },
      "category": "development",
      "homepage": "https://github.com/owner/repo/tree/main/plugin-directory"
    }
  ]
}
```

### Top-Level Fields

- `$schema`: Schema URL for validation (required)
- `name`: Marketplace identifier
- `description`: Marketplace description
- `owner`: Object with `name` and `email` (required)
- `plugins`: Array of plugin definitions (required)

### Plugin Object Fields

**Required:**
- `name`: Plugin identifier (must match plugin directory name)
- `description`: Plugin description
- `source`: Plugin location - can be:
  - String path: `"./plugin-directory"` (relative to marketplace.json)
  - Object: `{"source": "url", "url": "https://github.com/owner/repo.git"}` (for external Git repos)

**Optional:**
- `version`: Semantic version string
- `author`: Object with `name` and optional `email`
- `category`: Category identifier (e.g., "development", "productivity", "security", "testing", "database", "design", "monitoring", "deployment", "learning")
- `homepage`: Plugin homepage/documentation URL
- `strict`: Boolean (default: false) - whether plugin requires strict mode
- `lspServers`: Object defining Language Server Protocol configurations (for LSP plugins)
- `tags`: Array of tags (e.g., `["community-managed"]`)

### Source Field Patterns

**Local plugin (relative path):**
```json
"source": "./plugins/my-plugin"
```

**External plugin (Git repository):**
```json
"source": {
  "source": "url",
  "url": "https://github.com/owner/repo.git"
}
```

### Category Values (from official marketplace)

- `development`: Development tools, LSP servers, code intelligence
- `productivity`: Workflow automation, project management, collaboration
- `security`: Security scanning, vulnerability detection
- `testing`: Testing frameworks, browser automation
- `database`: Database integrations, data management
- `design`: Design tools, UI/UX integration
- `monitoring`: Error tracking, observability
- `deployment`: Deployment platforms, CI/CD
- `learning`: Educational tools, learning modes

### LSP Server Configuration Pattern

```json
{
  "name": "typescript-lsp",
  "source": "./plugins/typescript-lsp",
  "lspServers": {
    "typescript": {
      "command": "typescript-language-server",
      "args": ["--stdio"],
      "extensionToLanguage": {
        ".ts": "typescript",
        ".tsx": "typescriptreact",
        ".js": "javascript",
        ".jsx": "javascriptreact"
      }
    }
  }
}
```

### Key Insights

- **Schema validation**: Always include `$schema` for IDE validation
- **Relative paths**: Use `"./plugin-name"` for local plugins relative to marketplace.json location
- **External repos**: Use object syntax with `source: "url"` for Git repository sources
- **Categories**: Use standard categories for better discoverability
- **Versioning**: Include version numbers for tracking plugin updates
- **Homepage links**: Provide GitHub/documentation links for user reference

## Validation Checklist

### plugin.json Validation

**Required fields present:**
- [ ] `name` field exists and is kebab-case
- [ ] `description` field exists
- [ ] `author` object exists
- [ ] `author.name` field exists

**Optional fields (recommended):**
- [ ] `version` follows semver (X.Y.Z)
- [ ] `keywords` array for discoverability
- [ ] `repository` URL for source code
- [ ] `license` identifier present

**Common issues:**
- [ ] Name contains uppercase or spaces
- [ ] Missing author.name
- [ ] Invalid JSON syntax
- [ ] Manually listed components (not needed)

### marketplace.json Validation

**Required fields present:**
- [ ] `$schema` URL included
- [ ] `name` field exists
- [ ] `owner` object with name and email
- [ ] `plugins` array exists

**For each plugin entry:**
- [ ] `name` matches plugin directory
- [ ] `description` is present
- [ ] `source` path is correct (relative or URL)
- [ ] `version` follows semver
- [ ] `category` is from standard list
- [ ] `homepage` URL is valid

**Common issues:**
- [ ] Missing $schema
- [ ] Invalid source path
- [ ] Category not from standard list
- [ ] Plugin name mismatch with directory
- [ ] Invalid JSON syntax

## Common Mistakes

### Mistake 1: Overly Verbose Manifest

**Bad (plugin.json):**
```json
{
  "name": "my-plugin",
  "commands": ["./commands/cmd1.md", "./commands/cmd2.md"],
  "agents": ["./agents/agent1.md"],
  "skills": ["./skills/skill1"]
}
```

**Good:**
```json
{
  "name": "my-plugin",
  "description": "Plugin description",
  "author": {"name": "Author"}
}
```

**Why:** Auto-discovery handles component loading. Manual listing is unnecessary and redundant.

### Mistake 2: Wrong Name Format

**Bad:**
```json
{"name": "MyPlugin"}          // CamelCase
{"name": "my_plugin"}         // snake_case
{"name": "my plugin"}         // spaces
```

**Good:**
```json
{"name": "my-plugin"}         // kebab-case
```

### Mistake 3: Missing Schema in marketplace.json

**Bad:**
```json
{
  "name": "my-marketplace",
  "plugins": [...]
}
```

**Good:**
```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "my-marketplace",
  "plugins": [...]
}
```

### Mistake 4: Absolute Source Paths

**Bad (marketplace.json):**
```json
"source": "/Users/name/plugins/my-plugin"
```

**Good:**
```json
"source": "./my-plugin"
```

### Mistake 5: Invalid Category

**Bad:**
```json
"category": "tools"           // Not standard
"category": "misc"            // Not standard
```

**Good:**
```json
"category": "development"     // Standard
"category": "productivity"    // Standard
```

## Examples by Plugin Type

### Simple Utility Plugin

```json
{
  "name": "pdf-tools",
  "version": "1.0.0",
  "description": "PDF manipulation utilities",
  "author": {
    "name": "Developer",
    "email": "dev@example.com"
  },
  "license": "MIT",
  "keywords": ["pdf", "utilities", "documents"]
}
```

### Integration Plugin

```json
{
  "name": "api-client",
  "version": "0.2.0",
  "description": "HTTP API testing and development tools",
  "author": {
    "name": "API Team",
    "url": "https://api-team.example.com"
  },
  "homepage": "https://docs.example.com/api-plugin",
  "repository": "https://github.com/team/api-plugin",
  "license": "Apache-2.0",
  "keywords": ["api", "http", "testing", "rest", "graphql"]
}
```

### Enterprise Plugin

```json
{
  "name": "company-workflow",
  "version": "2.1.0",
  "description": "Internal workflow automation and compliance tools",
  "author": {
    "name": "Company DevTools",
    "email": "devtools@company.com",
    "url": "https://company.com/devtools"
  },
  "homepage": "https://docs.company.com/claude-plugin",
  "repository": "https://github.company.com/devtools/claude-workflow",
  "license": "Proprietary",
  "keywords": ["workflow", "compliance", "automation", "internal"]
}
```

## Versioning Best Practices

Follow semantic versioning (semver):

- **MAJOR**: Incompatible API changes
- **MINOR**: New functionality (backward-compatible)
- **PATCH**: Bug fixes (backward-compatible)

**Examples:**
- `0.1.0` - Initial development
- `0.2.0` - Added new skill
- `0.2.1` - Fixed bug in command
- `1.0.0` - First stable release
- `1.1.0` - Added new agent
- `2.0.0` - Breaking change to command interface

## Keywords Strategy

Choose keywords that:
1. Describe plugin purpose
2. Match user search terms
3. Indicate technology/domain
4. Differentiate from similar plugins

**Good keyword examples:**
- Technology: `["git", "docker", "kubernetes"]`
- Purpose: `["testing", "deployment", "validation"]`
- Domain: `["security", "performance", "database"]`
- Workflow: `["automation", "ci-cd", "code-review"]`

**Avoid:**
- Generic: `["plugin", "tool", "utility"]`
- Redundant: `["claude", "claude-code"]`
- Vague: `["helper", "misc", "various"]`

## Marketplace Distribution

To distribute your plugin via marketplace:

1. Create marketplace.json
2. Add plugin entry with proper metadata
3. Use meaningful category
4. Provide clear description
5. Include homepage for documentation
6. Version consistently
7. Test source path resolution
8. Validate JSON schema

## Summary

**plugin.json:**
- Keep minimal (name, description, author)
- Rely on auto-discovery
- Add version, keywords, repository
- Follow kebab-case naming
- Valid JSON syntax

**marketplace.json:**
- Include $schema for validation
- Use relative source paths
- Choose standard categories
- Provide complete metadata
- Version plugins properly
- Link to documentation

Both manifests should be concise, valid JSON that provides essential metadata without over-specification. Let Claude Code's auto-discovery handle component loading.
