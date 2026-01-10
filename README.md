# Frad's Claude Code Plugins

A curated collection of plugins and skills for Claude Code, designed to enhance development workflows with specialized agents and automation tools.

## Overview

This repository contains a comprehensive set of Claude Code plugins organized into development and productivity categories. Each plugin provides specialized functionality through commands and agents to streamline your coding workflow.

## Repository Structure

```
dotclaude/
├── .claude-plugin/
│   └── marketplace.json      # Plugin marketplace configuration
├── git/                      # Git automation plugin
├── gitflow/                  # GitFlow workflow plugin
├── github/                   # GitHub operations plugin
├── review/                   # Code review plugin
├── refactor/                 # Code refactoring plugin
├── swiftui/                  # SwiftUI architecture plugin
├── utils/                    # Utility commands plugin
├── office/                   # Patent architect plugin
└── README.md                 # This file
```

## Plugins

### Development Plugins

#### `git` - Git Automation
Conventional Git automation for commits and repository management.

**Commands:**
- `/commit` - Create atomic conventional git commits
- `/commit-and-push` - Create commits and push to remote
- `/gitignore` - Manage `.gitignore` files

**Features:**
- Conventional commit format support
- Atomic commit creation
- Automated gitignore management

#### `gitflow` - GitFlow Workflow
GitFlow workflow automation for feature, hotfix, and release branches.

**Commands:**
- `/start-feature` - Start new feature branch
- `/finish-feature` - Finish and merge feature branch
- `/start-hotfix` - Start new hotfix branch
- `/finish-hotfix` - Finish and merge hotfix branch
- `/start-release` - Start new release branch
- `/finish-release` - Finish and merge release branch

**Features:**
- Automated branch creation and management
- Proper GitFlow branching strategy
- Automatic merging and tagging

#### `refactor` - Code Refactoring
Agent and commands for code simplification and refactoring to improve code quality while preserving functionality.

**Agents:**
- `code-simplifier` - Code simplification specialist (Opus model)

**Commands:**
- `/refactor` - Refactor specific files/directories or recently modified code
- `/refactor-project` - Project-wide code refactoring

**Features:**
- Automatic code simplification
- Preserves functionality while improving clarity
- Follows project coding standards
- Uses **@code-simplifier** agent for guidance

#### `swiftui` - SwiftUI Architecture
SwiftUI Clean Architecture reviewer for iOS/macOS development.

**Agents:**
- `swiftui-clean-architecture-reviewer` - Specialized SwiftUI architecture reviewer

**Features:**
- Clean Architecture pattern enforcement
- SwiftUI best practices
- Architecture review and suggestions

### Productivity Plugins

#### `github` - GitHub Operations
GitHub project operations with quality gates.

**Commands:**
- `/create-issues` - Create GitHub issues
- `/create-pr` - Create pull requests with quality checks
- `/resolve-issues` - Resolve and close GitHub issues

**Features:**
- Automated PR creation with quality gates
- Issue management automation
- Quality assurance workflows

#### `review` - Code Review System
Multi-agent review system for enforcing high code quality.

**Agents:**
- `code-reviewer` - Expert reviewer for correctness, standards, and maintainability
- `security-reviewer` - Security-focused code review
- `tech-lead-reviewer` - Architecture and design review
- `ux-reviewer` - User experience and UI review

**Commands:**
- `/quick` - Quick code review
- `/hierarchical` - Hierarchical multi-agent review

**Features:**
- Multiple specialized reviewers
- Comprehensive code quality checks
- Security vulnerability detection
- Architecture and design analysis

#### `office` - Patent Architect
Specialized Claude Skill for patent application generation and intellectual property workflows.

**Skills:**
- `patent-architect` - Chinese patent application form generation

**Features:**
- Automatic prior art search (SerpAPI and Exa.ai)
- Chinese patent application form generation
- Patent terminology compliance
- Multiple embodiment generation

#### `utils` - Utility Commands
Utility commands for day-to-day automation.

**Commands:**
- `/continue` - Continue previous task or conversation
- `/create-command` - Create new command templates

**Features:**
- Task continuation
- Command template generation
- Daily workflow automation

## Plugin Structure

Each plugin follows Claude Code's standard plugin structure:

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json      # Plugin metadata (required)
├── commands/            # Slash commands (optional)
│   └── command-name.md
├── agents/              # Agent definitions (optional)
│   └── agent-name.md
├── skills/              # Skill definitions (optional)
│   └── skill-name/
│       └── SKILL.md
└── README.md            # Plugin documentation (optional)
```

### Plugin Configuration

Plugins are configured in `.claude-plugin/marketplace.json`:

```json
{
  "name": "plugin-name",
  "description": "Plugin description",
  "author": {
    "name": "Frad LEE",
    "email": "fradser@gmail.com"
  },
  "source": "./plugin-name",
  "category": "development"
}
```

## Installation

These plugins are configured through the `marketplace.json` file and are automatically available in Claude Code when this repository is set as a plugin source.

1. Ensure Claude Code is installed
2. Configure this repository as a plugin source
3. Plugins will be available for use in Claude Code

## Usage Examples

### Git Workflow

```bash
# Create a conventional commit
/commit feat: add user authentication

# Start a new feature
/start-feature user-profile-page

# Finish and merge feature
/finish-feature user-profile-page
```

### Code Review

```bash
# Quick review of current changes
/review quick

# Hierarchical review with all agents
/review hierarchical
```

### Code Refactoring

```bash
# Refactor recently modified code
/refactor

# Refactor specific files
/refactor src/auth/login.ts

# Project-wide refactoring
/refactor-project
```

### GitHub Operations

```bash
# Create a pull request
/create-pr

# Create issues
/create-issues "Fix authentication bug" "Update documentation"
```

## Development

### Adding a New Plugin

1. Create plugin directory structure:
   ```bash
   mkdir -p new-plugin/commands new-plugin/agents new-plugin/.claude-plugin
   ```

2. Create `plugin.json`:
   ```json
   {
     "name": "new-plugin",
     "description": "Plugin description",
     "author": {
       "name": "Frad LEE",
       "email": "fradser@gmail.com"
     }
   }
   ```

3. Add plugin to `marketplace.json`:
   ```json
   {
     "name": "new-plugin",
     "description": "Plugin description",
     "author": {
       "name": "Frad LEE",
       "email": "fradser@gmail.com"
     },
     "source": "./new-plugin",
     "category": "development"
   }
   ```

### Command Structure

Commands are defined as Markdown files in the `commands/` directory:

```markdown
---
allowed-tools: Bash(git:*), Read, Edit, MultiEdit, Glob, Grep, Task
description: Command description
argument-hint: [optional-argument]
---

## Context
- Current state information

## Requirements
- Task requirements

## Your Task
- Detailed task description
```

### Agent Structure

Agents are defined as Markdown files in the `agents/` directory:

```markdown
---
name: agent-name
description: Agent description
model: opus
---

You are an expert [role]...
```

## References

- [Claude Code Plugin Documentation](https://code.claude.com/docs/en/plugins)
- [Anthropic's Official Plugins Repository](https://github.com/anthropics/claude-plugins-official)

## License

This repository contains personal plugins and tools for Claude Code.

## Author

**Frad LEE**
- Email: fradser@gmail.com
- Plugins: A collection of specialized tools for development workflows
