# Plugin Optimizer

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
- **Automated Scripts**: Includes validation scripts for plugin.json, frontmatter, and file patterns

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

### Validation Scripts

Five automated validators in `scripts/` (all run automatically by `/optimize-plugin`):
- **Manifest structure**: Validates plugin.json schema and required fields
- **Component frontmatter**: Validates YAML frontmatter in component files
- **Tool invocations**: Checks for anti-patterns in tool usage
- **File patterns**: Validates naming conventions and directory structure
- **Token counter**: Validates skill token budgets (progressive disclosure)

#### Token Budget Validation

```bash
# Analyze a single skill
python scripts/count-tokens.py ./skills/my-skill

# Analyze all skills in a plugin
python scripts/count-tokens.py ./path/to/plugin --all

# Verbose output with file breakdown
python scripts/count-tokens.py . --all -v

# JSON output
python scripts/count-tokens.py . --all --json
```

Token budgets (from "Building agents with Skills"):
- **Metadata** (~50 tokens): Description in frontmatter, loaded during discovery
- **SKILL.md** (~500 tokens): Core instructions, loaded when invoked
- **References** (2000+ tokens): Detailed docs, loaded on demand

Install `tiktoken` for accurate counting: `uv run --with tiktoken python scripts/count-tokens.py`

See `skills/plugin-best-practices/SKILL.md` for detailed validation workflow and best practices.

## Structure

```
plugin-optimizer/
├── .claude-plugin/
│   └── plugin.json              # Manifest (skills: [./skills/plugin-best-practices/], commands: [./skills/optimize-plugin/])
├── agents/
│   └── plugin-optimizer.md      # Autonomous analysis agent
├── scripts/                     # Validation utilities
│   ├── validate-file-patterns.sh
│   ├── validate-plugin-json.sh
│   ├── validate-frontmatter.sh
│   ├── check-tool-invocations.sh
│   └── count-tokens.py          # Token budget validator
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
- Bash 4.0+ (for validation scripts)
- Basic understanding of Claude Code plugin structure

## Contributing

Issues and pull requests welcome at the repository.

## License

MIT

## Author

Frad LEE (fradser@gmail.com)
