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
| Command | Description | Model |
|---------|-------------|-------|
| `/git:commit` | Create atomic conventional git commit | `haiku` |
| `/git:commit-and-push` | Create commits and push to remote | `haiku` |
| `/git:gitignore` | Manage `.gitignore` files | `haiku` |

**Features:**
- Conventional commit format support
- Atomic commit creation
- Automated gitignore management

---

#### `gitflow` - GitFlow Workflow
GitFlow workflow automation for feature, hotfix, and release branches.

**Commands:**
| Command | Description | Model |
|---------|-------------|-------|
| `/gitflow:start-feature` | Start new feature branch | `haiku` |
| `/gitflow:finish-feature` | Finish and merge feature branch | `haiku` |
| `/gitflow:start-hotfix` | Start new hotfix branch | `haiku` |
| `/gitflow:finish-hotfix` | Finish and merge hotfix branch | `haiku` |
| `/gitflow:start-release` | Start new release branch | `haiku` |
| `/gitflow:finish-release` | Finish and merge release branch | `haiku` |

**Features:**
- Automated branch creation and management
- Proper GitFlow branching strategy
- Automatic merging and tagging
- Semantic versioning

---

#### `refactor` - Code Refactoring
Agent and skills for code simplification and refactoring to improve code quality while preserving functionality.

**Agents:**
| Agent | Description | Model | Color |
|-------|-------------|-------|-------|
| `code-simplifier` | Code simplification specialist | `opus` | `blue` |

**Skills:**
| Skill | Description |
|-------|-------------|
| `/refactor:refactor` | Refactor specific files/directories or recently modified code |
| `/refactor:refactor-project` | Project-wide code refactoring |

**Features:**
- Automatic code simplification
- Preserves functionality while improving clarity
- Follows project coding standards
- Language-specific references (TypeScript, Python, Go, Swift)

---

#### `swiftui` - SwiftUI Architecture
SwiftUI Clean Architecture reviewer for iOS/macOS development.

**Agents:**
| Agent | Description | Model | Color |
|-------|-------------|-------|-------|
| `swiftui-clean-architecture-reviewer` | Specialized SwiftUI architecture reviewer | `opus` | `red` |

**Features:**
- Clean Architecture pattern enforcement
- SwiftUI best practices (2024-2025)
- @Observable and @MainActor validation
- Architecture review and suggestions

---

### Productivity Plugins

#### `github` - GitHub Operations
GitHub project operations with quality gates.

**Commands:**
| Command | Description |
|---------|-------------|
| `/github:create-issues` | Create GitHub issues with TDD principles |
| `/github:create-pr` | Create pull requests with quality checks |
| `/github:resolve-issues` | Resolve issues using isolated worktrees |

**Features:**
- Automated PR creation with quality gates
- Issue management automation
- TDD workflow with worktrees
- Multi-agent collaboration

---

#### `review` - Code Review System
Multi-agent review system for enforcing high code quality.

**Agents:**
| Agent | Description | Model | Color |
|-------|-------------|-------|-------|
| `code-reviewer` | Expert reviewer for correctness, standards, and maintainability | `sonnet` | `blue` |
| `security-reviewer` | Security-focused code review | `sonnet` | `green` |
| `tech-lead-reviewer` | Architecture and design review | `sonnet` | `purple` |
| `ux-reviewer` | User experience and UI review | `sonnet` | `orange` |

**Commands:**
| Command | Description |
|---------|-------------|
| `/review:quick` | Quick code review with selective agents |
| `/review:hierarchical` | Comprehensive multi-agent review |

**Features:**
- Multiple specialized reviewers
- Comprehensive code quality checks
- Security vulnerability detection
- Architecture and design analysis

---

#### `office` - Patent Architect
Specialized Claude Skill for patent application generation and intellectual property workflows.

**Skills:**
| Skill | Description |
|-------|-------------|
| `/office:patent-architect` | Chinese patent application form generation |

**Features:**
- Automatic prior art search (SerpAPI and Exa.ai)
- Chinese patent application form generation
- Patent terminology compliance
- Multiple embodiment generation

---

#### `utils` - Utility Commands
Utility commands for day-to-day automation.

**Commands:**
| Command | Description |
|---------|-------------|
| `/utils:continue` | Continue previous task or conversation |
| `/utils:create-command` | Create new command templates |

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
/git:commit

# Start a new feature
/gitflow:start-feature user-profile-page

# Finish and merge feature
/gitflow:finish-feature
```

### Code Review

```bash
# Quick review of current changes
/review:quick

# Comprehensive multi-agent review
/review:hierarchical
```

### Code Refactoring

```bash
# Refactor recently modified code
/refactor:refactor

# Refactor specific files
/refactor:refactor src/auth/login.ts

# Project-wide refactoring
/refactor:refactor-project
```

### GitHub Operations

```bash
# Create a pull request
/github:create-pr

# Create issues
/github:create-issues "Fix authentication bug" "Update documentation"

# Resolve issues with TDD
/github:resolve-issues
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
model: haiku
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
color: blue
tools: Read, Edit, MultiEdit, Glob, Grep, Bash
---

You are an expert [role]...
```

### Skill Structure

Skills are defined as `SKILL.md` files in skill directories:

```markdown
---
name: skill-name
description: Skill description
version: 1.0.0
context: fork
agent: agent-name
allowed-tools: Bash(git:*), Read, Edit, Task
---

# Skill Title

## Workflow

1. Step one
2. Step two
...
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
