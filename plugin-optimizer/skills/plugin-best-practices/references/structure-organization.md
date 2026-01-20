# Plugin Structure & Organization

Based on the official documentation and architectural patterns, here is the comprehensive guide to plugin structure and organization.

## 1. Plugin Structure & Organization

**Must Do**

- **Follow Standard Layout:** Place components in the root directories: `commands/`, `agents/`, `skills/`, and `hooks/`.
- **Place Manifest Correctly:** Ensure `plugin.json` is located in the `.claude-plugin/` directory.
- **Use Portable Paths:** Always use `${CLAUDE_PLUGIN_ROOT}` environment variable for file references. Never use hardcoded absolute paths or relative paths assuming a working directory.
- **Use Kebab-Case:** Name all directories and files using `kebab-case` (e.g., `code-review.md`, `api-testing/`).

**Should Do**

- **Rely on Auto-Discovery:** Keep `plugin.json` lean by letting Claude discover components automatically rather than manually listing every file.
- **Group Complex Components:** Use subdirectories for organization when you have 15+ items (e.g., `commands/ci/build.md`), though note this requires custom path configuration in `plugin.json`.
- **Include READMEs:** Place a README in the plugin root and distinct READMEs in script subdirectories explaining dependencies.

**Avoid**

- **Nesting Components in Config:** Do not put commands or agents inside the `.claude-plugin/` directory.
- **Generic Names:** Avoid names like `utils`, `misc`, or `temp`. Be descriptive (`date-utils`, `pdf-processing`).

### Plugin Manifest Patterns (plugin.json)

**Location:** `.claude-plugin/plugin.json`

**Core Pattern (Minimal - Recommended):**

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

**Required Fields:**
- `name`: Plugin identifier (kebab-case, matches directory name)
- `description`: One-line summary of plugin functionality
- `author`: Object with at least `name` field

**Optional Fields:**
- `version`: Semantic version string (e.g., "0.1.0", "1.2.3")
- `author.email`: Author email address
- `author.url`: Author website URL
- `homepage`: Plugin homepage/documentation URL
- `repository`: Repository URL (GitHub, GitLab, etc.)
- `license`: License identifier (e.g., "MIT", "Apache-2.0")
- `keywords`: Array of searchable keywords (e.g., `["git", "automation", "workflow"]`)

**Key Insights:**
- **Keep it minimal**: Official plugins intentionally use minimal manifests - rely on auto-discovery
- **Auto-discovery works**: Claude automatically discovers `commands/`, `agents/`, `skills/`, and `hooks/` directories
- **No component listing**: Do not manually list commands, agents, or skills in `plugin.json`
- **External plugins may be verbose**: Third-party plugins (like Stripe) may include more metadata for marketplace visibility

**Examples from Official Plugins:**

```json
// Minimal (most common pattern)
{
  "name": "code-review",
  "description": "Automated code review for pull requests using multiple specialized agents",
  "author": {
    "name": "Anthropic",
    "email": "support@anthropic.com"
  }
}

// With version and homepage
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

## General Tips

- **Security First:** Treat all inputs in hooks and commands as potentially untrusted.
- **Test with Debug:** Use `claude --debug` to see detailed logs of hook execution and agent routing.
- **Portability:** Ensure scripts work across different environments (macOS/Linux). Avoid system-specific tools unless documented as dependencies.
- **Version Control:** Use the `version` field in `plugin.json` and follow semantic versioning.
