# Plugin Directory Structure

## Standard plugin layout

A complete plugin follows this structure. **Modern plugins** prioritize Skills over Commands for better modularity.

```
enterprise-plugin/
├── .claude-plugin/           # Metadata directory (only plugin.json belongs here)
│   └── plugin.json
├── skills/                   # Agent Skills (RECOMMENDED)
│   ├── commit/
│   │   └── SKILL.md
│   ├── code-reviewer/
│   │   ├── SKILL.md
│   │   └── references/
│   └── pdf-processor/
│       ├── SKILL.md
│       └── scripts/
├── commands/                 # Skills as flat .md files (legacy; use skills/ for new plugins)
│   ├── status.md
│   └── logs.md
├── agents/                   # Subagent definitions
│   ├── security-reviewer.md
│   ├── performance-tester.md
│   └── compliance-checker.md
├── output-styles/            # Response-formatting style definitions
│   └── terse.md
├── themes/                   # Color theme JSON files
│   └── dracula.json
├── monitors/                 # Background monitor configurations
│   └── monitors.json
├── hooks/                    # Hook configurations
│   ├── hooks.json           # Main hook config
│   └── security-hooks.json  # Additional hooks
├── bin/                      # Plugin executables added to Bash PATH
│   └── my-tool               # Invokable as a bare command in any Bash tool call
├── settings.json             # Plugin default settings (agent + subagentStatusLine keys)
├── .mcp.json                 # MCP server definitions
├── .lsp.json                 # LSP server configurations
├── scripts/                  # Hook and utility scripts
│   ├── security-scan.sh      # Must be executable with shebang
│   ├── format-code.py        # Must be executable with shebang
│   └── deploy.js             # Must be executable with shebang
├── LICENSE                   # License file
└── CHANGELOG.md              # Version history
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

> **Warning**: The `.claude-plugin/` directory contains the `plugin.json` file. All other directories (commands/, agents/, skills/, output-styles/, themes/, monitors/, hooks/, bin/) MUST be at the plugin root, not inside `.claude-plugin/`.

> **Best Practice**: See `./references/manifest-schema.md` for plugin.json declaration guidance.

## File locations reference

| Component         | Default Location             | Purpose                                                                                    |
| :---------------- | :--------------------------- | :----------------------------------------------------------------------------------------- |
| **Manifest**      | `.claude-plugin/plugin.json` | Plugin metadata (optional)                                                                 |
| **Skills**        | `skills/`                    | Skills with `<name>/SKILL.md` structure (recommended for new plugins)                      |
| **Commands**      | `commands/`                  | Skills as flat Markdown files (legacy form)                                                |
| **Agents**        | `agents/`                    | Subagent Markdown files                                                                    |
| **Output styles** | `output-styles/`             | Output style definitions                                                                   |
| **Themes**        | `themes/`                    | Color theme definitions                                                                    |
| **Monitors**      | `monitors/monitors.json`     | Background monitor configurations                                                          |
| **Hooks**         | `hooks/hooks.json`           | Hook configuration                                                                         |
| **MCP servers**   | `.mcp.json`                  | MCP server definitions                                                                     |
| **LSP servers**   | `.lsp.json`                  | Language server configurations                                                             |
| **Executables**   | `bin/`                       | Files added to Bash tool's PATH while plugin is enabled                                    |
| **Settings**      | `settings.json`              | Default plugin config (only `agent` and `subagentStatusLine` keys are currently supported) |
| **Scripts**       | `scripts/`                   | Hook and utility scripts (must be executable with shebang)                                 |

## Script Requirements

Scripts MUST be executable (`chmod +x`), include proper shebang lines (`#!/bin/bash`, `#!/usr/bin/env python3`, etc.), and use `${CLAUDE_PLUGIN_ROOT}` in paths. See `./references/debugging.md` for troubleshooting.

## Path Reference Patterns

Use appropriate path patterns based on context:

| Context | Pattern | Example |
|---------|---------|---------|
| Same skill references | Relative: `./` | `./references/design-creation.md` |
| Cross-skill shared references | Relative: `../../` | `../../skills/references/git-commit.md` |
| Scripts with absolute paths | Variable: `${CLAUDE_PLUGIN_ROOT}` | `${CLAUDE_PLUGIN_ROOT}/scripts/validate.py` |
| MCP/LSP environment variables | Variable: `${ENV_VAR}` | `${GITHUB_TOKEN}` |

**Example in SKILL.md**:
```markdown
See `./references/design-creation.md` for sub-agent patterns.
See `../../skills/references/git-commit.md` for commit patterns.
```

**Example in scripts**:
```bash
#!/bin/bash
"${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin.py" "$1"
```
