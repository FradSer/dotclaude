# Plugin Directory Structure

## Standard plugin layout

A complete plugin follows this structure. **Modern plugins** prioritize Skills over Commands for better modularity.

```
enterprise-plugin/
├── .claude-plugin/           # Metadata directory
│   └── plugin.json          # Required: plugin manifest (declare skills here)
├── skills/                   # Agent Skills (RECOMMENDED)
│   ├── commit/
│   │   └── SKILL.md
│   ├── code-reviewer/
│   │   ├── SKILL.md
│   │   └── references/
│   └── pdf-processor/
│       ├── SKILL.md
│       └── scripts/
├── commands/                 # Legacy commands (optional)
│   ├── status.md
│   └── logs.md
├── agents/                   # Default agent location
│   ├── security-reviewer.md
│   ├── performance-tester.md
│   └── compliance-checker.md
├── hooks/                    # Hook configurations
│   ├── hooks.json           # Main hook config
│   └── security-hooks.json  # Additional hooks
├── .mcp.json                # MCP server definitions
├── .lsp.json                # LSP server configurations
├── scripts/                 # Hook and utility scripts
│   ├── security-scan.sh     # Must be executable with shebang
│   ├── format-code.py       # Must be executable with shebang
│   └── deploy.js            # Must be executable with shebang
├── LICENSE                  # License file
└── CHANGELOG.md             # Version history
```

**Example plugin.json with explicit skill declarations**:
```json
{
  "name": "enterprise-plugin",
  "version": "1.0.0",
  "description": "Enterprise automation tools",
  "commands": [
    "./skills/commit/",
    "./skills/code-reviewer/",
    "./skills/pdf-processor/"
  ]
}
```

> **Warning**: The `.claude-plugin/` directory contains the `plugin.json` file. All other directories (commands/, agents/, skills/, hooks/) MUST be at the plugin root, not inside `.claude-plugin/`.

> **Best Practice**: See `./references/manifest-schema.md` for plugin.json declaration guidance.

## File locations reference

| Component       | Default Location             | Purpose                          | Priority      |
| :-------------- | :--------------------------- | :------------------------------- | :------------ |
| **Manifest**    | `.claude-plugin/plugin.json` | Required metadata file           | Required      |
| **Skills**      | `skills/`                    | Agent Skills with SKILL.md files | **Recommended** |
| **Commands**    | `commands/`                  | Legacy slash command files       | Optional      |
| **Agents**      | `agents/`                    | Subagent Markdown files          | -             |
| **Hooks**       | `hooks/hooks.json`           | Hook configuration               | -             |
| **MCP servers** | `.mcp.json`                  | MCP server definitions           | -             |
| **LSP servers** | `.lsp.json`                  | Language server configurations   | -             |
| **Scripts**     | `scripts/`                    | Hook and utility scripts         | -             |

## Script Requirements

Scripts MUST be executable (`chmod +x`), include proper shebang lines (`#!/bin/bash`, `#!/usr/bin/env python3`, etc.), and use `${CLAUDE_PLUGIN_ROOT}` in paths. See `./references/debugging.md` for troubleshooting.
