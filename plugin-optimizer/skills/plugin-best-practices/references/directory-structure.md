# Plugin Directory Structure

## Standard plugin layout

A complete plugin follows this structure:

```
enterprise-plugin/
├── .claude-plugin/           # Metadata directory
│   └── plugin.json          # Required: plugin manifest
├── commands/                 # Default command location
│   ├── status.md
│   └── logs.md
├── agents/                   # Default agent location
│   ├── security-reviewer.md
│   ├── performance-tester.md
│   └── compliance-checker.md
├── skills/                   # Agent Skills
│   ├── code-reviewer/
│   │   └── SKILL.md
│   └── pdf-processor/
│       ├── SKILL.md
│       └── scripts/
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

> **Warning**: The `.claude-plugin/` directory contains the `plugin.json` file. All other directories (commands/, agents/, skills/, hooks/) must be at the plugin root, not inside `.claude-plugin/`.

## File locations reference

| Component       | Default Location             | Purpose                          |
| :-------------- | :--------------------------- | :------------------------------- |
| **Manifest**    | `.claude-plugin/plugin.json` | Required metadata file           |
| **Commands**    | `commands/`                  | Slash command Markdown files     |
| **Agents**      | `agents/`                    | Subagent Markdown files          |
| **Skills**      | `skills/`                    | Agent Skills with SKILL.md files |
| **Hooks**       | `hooks/hooks.json`           | Hook configuration               |
| **MCP servers** | `.mcp.json`                  | MCP server definitions           |
| **LSP servers** | `.lsp.json`                  | Language server configurations   |
| **Scripts**     | `scripts/`                    | Hook and utility scripts         |

## Script Requirements

Scripts must be executable (`chmod +x`), include proper shebang lines (`#!/bin/bash`, `#!/usr/bin/env python3`, etc.), and use `${CLAUDE_PLUGIN_ROOT}` in paths. See `references/debugging.md` (lines 47-50) for troubleshooting.
