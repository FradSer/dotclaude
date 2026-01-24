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

The Plugin Optimizer analyzes existing Claude Code plugins to ensure they follow official standards and best practices. It checks plugin structure, component formatting, metadata completeness, and tool invocation patterns, then provides detailed optimization reports with actionable recommendations.

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

WARNING (3):
- commands/test.md:12 - Explicit tool call "Use Read tool" should be descriptive
- agents/reviewer.md:8 - Missing <example> blocks in description
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

**Technical implementation**: User-invocable skill (`user-invocable: true`) stored in `skills/optimize-plugin/` and registered in `plugin.json` `commands` array. This follows the modern pattern where skills can serve as commands.

**What it does**: Executes a 7-phase validation and optimization workflow that launches the plugin-optimizer agent to analyze plugin structure, fix issues, and generate comprehensive reports.

### Skill: plugin-best-practices

Background knowledge base (non-user-invocable) loaded by the plugin-optimizer agent. Covers:
- Plugin structure and organization standards
- Component development patterns (commands, agents, skills, hooks)
- Tool invocation best practices
- File format validation rules
- Progressive disclosure and redundancy analysis

**Technical implementation**: Knowledge-type skill (`user-invocable: false`) stored in `skills/plugin-best-practices/` with extensive `references/` subdirectory, registered in `plugin.json` `skills` array.

### Agent: plugin-optimizer

Autonomous analysis agent launched by the optimize-plugin workflow. Validates plugins against best practices, applies automated fixes, performs redundancy analysis, and generates quality reports. Preloads the plugin-best-practices skill for validation rules.

### Validation Scripts

Four automated validators in `scripts/`:
- Manifest structure and required fields
- Component frontmatter (YAML)
- Tool invocation anti-patterns
- File naming and format conventions

See `skills/plugin-best-practices/SKILL.md` for detailed validation workflow and best practices knowledge.

## Structure

```
plugin-optimizer/
├── .claude-plugin/
│   └── plugin.json              # Manifest (commands: [./skills/optimize-plugin/])
├── agents/
│   └── plugin-optimizer.md      # Analysis agent
├── scripts/                     # Validation utilities
│   ├── validate-file-patterns.sh
│   ├── validate-plugin-json.sh
│   ├── validate-frontmatter.sh
│   └── check-tool-invocations.sh
├── skills/
│   ├── optimize-plugin/         # User-invocable skill (registered as command)
│   │   └── SKILL.md            # 7-phase optimization workflow
│   └── plugin-best-practices/   # Knowledge-type skill (agent-only)
│       ├── SKILL.md            # Core validation rules (121 lines)
│       └── references/          # Detailed documentation (14 files)
│           └── components/      # Component-specific guides
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
