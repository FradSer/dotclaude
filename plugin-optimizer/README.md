# Plugin Optimizer

Validates and optimizes Claude Code plugins against official best practices and file patterns.

## Overview

The Plugin Optimizer analyzes existing Claude Code plugins to ensure they follow official standards and best practices. It checks plugin structure, component formatting, metadata completeness, and tool invocation patterns, then provides detailed optimization reports with actionable recommendations.

## Features

- **Comprehensive Validation**: Checks against official Claude Code plugin best practices and file pattern standards
- **Multi-level Issue Detection**: Reports critical errors, warnings, and informational suggestions
- **Best Practices Compliance**: Generates checklist showing which standards are met/violated
- **Auto-fix Suggestions**: Provides exact Edit tool parameters for quick fixes (not auto-applied)
- **Automated Scripts**: Includes validation scripts for plugin.json, frontmatter, and file patterns

## Installation

### From Marketplace

```bash
claude plugin install plugin-optimizer
```

### Local Development

```bash
# Clone or navigate to the plugin directory
cd /path/to/dotclaude
claude --plugin-dir ./plugin-optimizer
```

## Usage

### Optimize a Plugin

```bash
/optimize ./path/to/your-plugin
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

### Skill: plugin-best-practices

Comprehensive knowledge base covering:
- Plugin structure and organization
- Command, agent, skill, and hook development
- TodoWrite tool usage standards
- Tool invocation patterns
- File format patterns and conventions

### Command: /optimize

User-initiated plugin optimization accepting plugin path as argument.

### Agent: plugin-optimizer

Autonomous analysis agent that validates plugins and generates detailed reports.

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
│   └── plugin.json
├── commands/
│   └── optimize.md
├── agents/
│   └── plugin-optimizer.md
├── scripts/             # Validation utilities
├── skills/
│   └── plugin-best-practices/
│       ├── SKILL.md
│       ├── references/          # Detailed documentation
│       └── examples/            # Good/bad plugin examples
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
