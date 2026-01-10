# FradSer's Claude Code Plugins

A curated collection of plugins and skills for Claude Code, designed to enhance development workflows with specialized agents and automation tools.

## Structure

- **`/plugins`** - Custom plugins and skills collection
  - **`git`** - Conventional Git and GitFlow automation
  - **`github`** - GitHub project operations with quality gates
  - **`review`** - Multi-agent review system for code quality
  - **`swiftui`** - SwiftUI Clean Architecture reviewer
  - **`utils`** - Utility commands for day-to-day automation
  - **`patent-architect`** - Specialized Claude Skill for patent application generation

- **`/.research/claude-plugins-official`** - Reference implementation (Git submodule) from Anthropic's official plugins directory

## Plugin Structure

Each plugin follows Claude Code's standard plugin structure:

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json      # Plugin metadata (required)
├── commands/            # Slash commands (optional)
├── agents/              # Agent definitions (optional)
├── skills/              # Skill definitions (optional)
└── README.md            # Plugin documentation
```

## Installation

These plugins are configured through the `marketplace.json` file and can be used directly within Claude Code.

## Plugin Details

### Development Plugins
- **git**: Git and GitFlow workflow automation with conventional commits
- **github**: GitHub operations including PR creation and issue management
- **swiftui**: SwiftUI architecture review and best practices enforcement

### Productivity Plugins
- **review**: Multi-agent code review system with specialized reviewers
- **utils**: Daily automation utilities and helper commands
- **patent-architect**: AI-powered patent application generation and IP workflow tools

## Development Notes

This repository follows the structure established in [Anthropic's official plugins repository](https://github.com/anthropics/claude-plugins-official) as a reference implementation.

For more information on developing Claude Code plugins, see the [official documentation](https://code.claude.com/docs/en/plugins).
