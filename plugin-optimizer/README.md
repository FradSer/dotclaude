# Plugin Optimizer

**Version:** 0.11.2

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
- **Best Practices Compliance**: Generates checklist showing which standards are met/violated
- **Auto-fix Suggestions**: Provides exact Edit tool parameters for quick fixes (not auto-applied)
- **Unified Validator**: Single Python script covering plugin.json, frontmatter, file patterns, tool invocations, and token budgets

## Usage

### Optimize a Plugin

```bash
/optimize-plugin ./path/to/your-plugin
```

The optimizer will validate your plugin against official best practices and generate a comprehensive report with actionable fix suggestions.

### Example Output

```
Plugin Optimization Report: my-plugin
======================================

✅ BEST PRACTICES COMPLIANCE
Validates 6 core aspects: structure, commands, agents, skills, tool patterns, and file formats
- [✓] Plugin Structure & Organization
- [✗] Command Development (2 issues)
- [✓] Agent Design
- [✗] Tool Invocation Patterns (3 issues)

⚠️  ISSUES FOUND

CRITICAL (1):
- commands/deploy.md:5 - Missing required 'description' field in frontmatter

WARNING (2):
- commands/test.md:12 - Explicit tool call "Use Read tool" should be descriptive
- skills/api/SKILL.md:23 - Using second person "You should" instead of imperative

INFO (1):
- .claude-plugin/plugin.json - Missing optional 'keywords' field for discoverability

🔧 AUTO-FIX SUGGESTIONS

commands/deploy.md:
  old_string: "---\nargument-hint: <service>"
  new_string: "---\ndescription: \"Deploy application to specified service\"\nargument-hint: <service>"
```

## Components

### Command: /optimize-plugin

User-initiated plugin optimization workflow accepting plugin path as argument.

**Technical implementation**: User-invocable skill (`user-invocable: true`) stored in `skills/optimize-plugin/` and registered in `plugin.json` `commands` array following the modern pattern where skills serve as commands.

**What it does**: Executes a multi-phase validation and optimization workflow that launches the plugin-optimizer agent to analyze plugin structure, fix issues, and generate comprehensive reports.

### Skill: plugin-best-practices

Background knowledge base (non-user-invocable) loaded by the plugin-optimizer agent. Provides comprehensive validation standards including plugin structure, component patterns, tool invocation best practices, file format rules, and progressive disclosure guidelines.

**Technical implementation**: Knowledge-type skill (`user-invocable: false`) stored in `skills/plugin-best-practices/` with extensive `references/` subdirectory, registered in `plugin.json` `skills` array.

### Agent: plugin-optimizer

Autonomous analysis agent launched by the optimize-plugin workflow. Validates plugins against best practices, applies automated fixes, performs redundancy analysis, and generates quality reports. Preloads the plugin-best-practices skill for comprehensive validation rules.

### Validation Script

A unified Python validator (`scripts/validate-plugin.py`) runs five checks automatically:

- **Structure**: File patterns, naming conventions, directory layout
- **Manifest**: plugin.json schema and required fields
- **Frontmatter**: YAML frontmatter in component files
- **Tool invocations**: Anti-pattern detection in tool usage
- **Token budgets**: Progressive disclosure compliance

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
│   └── plugin.json              # Manifest (skills: [./skills/plugin-best-practices/], commands: [./skills/optimize-plugin/])
├── agents/
│   └── plugin-optimizer.md      # Autonomous analysis agent
├── scripts/                     # Validation utilities
│   └── validate-plugin.py       # Unified validator (structure, manifest, frontmatter, tools, tokens)
├── skills/
│   ├── optimize-plugin/         # User-invocable skill (registered as command)
│   │   ├── SKILL.md            # Multi-phase optimization workflow
│   │   └── references/          # Workflow details (4 files)
│   │       ├── template-validation.md
│   │       ├── tool-patterns.md
│   │       ├── workflow-phases.md
│   │       └── report-template.md
│   └── plugin-best-practices/   # Knowledge-type skill (agent-only)
│       ├── SKILL.md            # Core validation rules
│       └── references/          # Detailed documentation (17 files)
│           ├── components/      # Component-specific guides (6 files)
│           ├── component-model.md
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
