# Plugin Optimizer

**displayName:** Plugin Optimizer
**Version:** 0.13.3

Validates and optimizes Claude Code plugins against official best practices and file patterns.

## Installation

### From Marketplace

```bash
claude plugin install plugin-optimizer@frad-dotclaude
```

### Local Development

```bash
# Clone or navigate to the plugin directory
cd /path/to/dotclaude
claude --plugin-dir ./plugin-optimizer
```

## Overview

The Plugin Optimizer validates Claude Code plugins against official best practices and file patterns. It checks plugin structure, component formatting, metadata completeness, and tool invocation patterns, providing detailed optimization reports with actionable recommendations.

## Features

- **Comprehensive Validation**: Checks against official Claude Code plugin best practices and file pattern standards
- **Multi-level Issue Detection**: Reports critical errors, warnings, and informational suggestions
- **Actionable Suggestions**: Each issue carries a `help:` line with a concrete fix (the validator is read-only — it never applies changes)
- **Unified Validator**: Single Python script covering plugin.json, frontmatter, file patterns, tool invocations, and token budgets

## Usage

### Optimize a Plugin

```bash
/optimize-plugin ./path/to/your-plugin
```

The optimizer will validate your plugin against official best practices and generate a comprehensive report with actionable fix suggestions.

### Example Output

```
$ python3 plugin-optimizer/scripts/validate-plugin.py lark --check=frontmatter
lark  (commands=0, agents=0, skills=27)

  skills/lark-attendance/lark-attendance.md:4  should  Description missing trigger phrases (when to use this skill)
                                                       │ description: 飞书考勤打卡：查询自己的考勤打卡记录...
                                                       help: Include both what the skill does AND when to use it. Example: 'Validates plugins. Use when validating plugin structure...'

PASSED  1 should
```

Each diagnostic is `path:line  severity  message`, optionally followed by the
offending source (`│`) and a `help:` suggestion. Severity is `must`, `should`, or
`may`. `-v` adds a list of passing checks; `--json` emits the same data as JSON
for scripting. Exit codes: `0` passed, `1` a MUST violation, `2` token budget
critical. The validator reports issues only — it does not modify files.

## Components

### Command: /optimize-plugin

User-initiated plugin optimization workflow accepting plugin path as argument.

**Technical implementation**: User-invocable skill (`user-invocable: true`) stored in `skills/optimize-plugin/`. Claude Code auto-discovers `skills/`; `user-invocable` in the frontmatter is what exposes `/plugin-optimizer:optimize-plugin`. Do not declare skill directories under `plugin.json` `commands` — that registers each skill twice.

**What it does**: Executes a multi-phase validation and optimization workflow that launches the plugin-optimizer agent to analyze plugin structure, fix issues, and generate comprehensive reports.

### Skill: plugin-best-practices

Background knowledge base (non-user-invocable) loaded by the plugin-optimizer agent. Provides comprehensive validation standards including plugin structure, component patterns, tool invocation best practices, file format rules, and progressive disclosure guidelines.

**Technical implementation**: Knowledge-type skill (`user-invocable: false`) stored in `skills/plugin-best-practices/` with extensive `references/` subdirectory. Claude Code auto-discovers `skills/`; the `skills` key in `plugin.json` is not required for it (that key only adds extra, non-default skill directories).

### Agent: plugin-optimizer

Autonomous analysis agent launched by the optimize-plugin workflow. Validates plugins against best practices, applies automated fixes, performs redundancy analysis, and generates quality reports. Preloads the plugin-best-practices skill for comprehensive validation rules.

### Validation Script

A unified Python validator (`scripts/validate-plugin.py`) runs five checks automatically:

- **Structure**: File patterns, naming conventions, directory layout (incl. `monitors/`, `themes/`, `output-styles/`, `bin/`, `lsp-servers/`), and skill folder auxiliary-file check (`README.md`/`CHANGELOG.md` inside a skill are flagged; spec is permissive on other layouts)
- **Manifest**: plugin.json schema, required fields, `displayName` field, and unknown-field warnings (typo detection). Validates `monitors`, `themes`, `outputStyles`, `lspServers`, `mcpServers`, `userConfig`, `dependencies` paths and shapes
- **Frontmatter**: YAML frontmatter in components. For agents, enforces the upstream-forbidden fields (`hooks`, `mcpServers`, `permissionMode`) and `isolation: "worktree"` constraint
- **Tool invocations**: Anti-pattern detection in tool usage
- **Token budgets**: Progressive disclosure compliance

**Severity levels** (RFC 2119): `MUST` violations fail validation; `SHOULD` are recommended; `MAY` are optional.

**Exit codes**: `0` clean, `1` MUST violations, `2` token budget critical (refactor required).

**JSON mode** (`--json`) emits machine-readable output for CI integration.

```bash
# Run all validators
python3 scripts/validate-plugin.py <plugin-path>

# Run specific checks
python3 scripts/validate-plugin.py <plugin-path> --check=tokens
python3 scripts/validate-plugin.py <plugin-path> --check=manifest,frontmatter

# Verbose or JSON output
python3 scripts/validate-plugin.py <plugin-path> -v
python3 scripts/validate-plugin.py <plugin-path> --json
```

Token budgets (from "Building agents with Skills"):
- **Metadata** (~50 tokens): Description in frontmatter, loaded during discovery
- **SKILL.md** (~500 tokens): Core instructions, loaded when invoked
- **References** (2000+ tokens): Detailed docs, loaded on demand

Install `tiktoken` for accurate counting: `uv run --with tiktoken python3 scripts/validate-plugin.py`

See `skills/plugin-best-practices/SKILL.md` for detailed validation rules.

## Structure

```
plugin-optimizer/
├── .claude-plugin/
│   └── plugin.json              # Manifest
├── agents/
│   └── plugin-optimizer.md      # Autonomous analysis agent
├── scripts/                     # Validation utilities
│   └── validate-plugin.py       # Unified validator (structure, manifest, frontmatter, tools, tokens)
├── skills/
│   ├── optimize-plugin/         # User-invocable skill (auto-discovered, user-invocable: true)
│   │   └── SKILL.md            # Multi-phase optimization workflow
│   └── plugin-best-practices/   # Knowledge-type skill (agent-only)
│       ├── SKILL.md            # Core validation rules
│       └── references/          # Detailed documentation (22 files)
│           ├── components/      # Component-specific guides (9 files)
│           │   ├── agents.md
│           │   ├── commands.md
│           │   ├── hooks.md
│           │   ├── lsp-servers.md
│           │   ├── mcp-servers.md
│           │   ├── monitors.md
│           │   ├── output-styles.md
│           │   ├── skills.md
│           │   └── themes.md
│           ├── component-model.md
│           ├── directory-structure.md
│           ├── manifest-schema.md
│           ├── validation-checklist.md
│           └── parallel-execution.md
└── README.md
```

## Prerequisites

- Claude Code CLI
- Python 3.8+ (for validation script)
- Basic understanding of Claude Code plugin structure

## Contributing

Issues and pull requests welcome at the repository.

## License

MIT

## Author

Frad LEE (fradser@gmail.com)
