# Frad's Claude Code Plugins

A curated collection of plugins and skills for Claude Code, designed to enhance development workflows with specialized agents and automation tools.

## Installation

### Add Plugin Marketplace

First, add this repository as a plugin marketplace:

```bash
claude plugin marketplace add FradSer/dotclaude
```

This will make all plugins in this marketplace available for installation.

### Install Individual Plugins

After adding the marketplace, you can install any plugin using:

```bash
claude plugin install <plugin-name>@frad-dotclaude
```

## Available Plugins

### git - Git Automation

Conventional Git automation for commits and repository management with AI code quality check.

```bash
claude plugin install git@frad-dotclaude
```

**Key Features:**
- Conventional commit format support with AI code quality check
- Atomic commit creation with Co-Authored-By footer
- Automated gitignore management with OS/language detection
- Pre-commit hook validation
- Project-specific `.claude/git.local.md` configuration

---

### gitflow - GitFlow Workflow

GitFlow workflow automation for feature, hotfix, and release branches with semantic versioning.

```bash
claude plugin install gitflow@frad-dotclaude
```

**Key Features:**
- Automated branch creation and management
- Proper GitFlow branching strategy
- Automatic merging and tagging
- Semantic versioning with version bump commits
- Pre-finish test validation
- Automatic changelog updates
- GitHub release creation (finish-release)
- Workflow coordination and orchestration

---

### github - GitHub Operations

GitHub project operations with comprehensive quality validation and TDD workflows.

```bash
claude plugin install github@frad-dotclaude
```

**Key Features:**
- Automated PR creation with comprehensive quality validation
- Issue creation with TDD principles and proper labels
- TDD workflow with isolated worktrees
- Conventional commits enforcement
- Security scanning for sensitive files
- Quality checks (lint, test, build)
- Auto-closing keywords for issues

---

### review - Code Review System

Multi-agent review system for enforcing high code quality with selective and hierarchical review modes.

```bash
claude plugin install review@frad-dotclaude
```

**Key Features:**
- Selective specialized reviewers (code, security, tech-lead, UX)
- Priority/confidence matrix for findings
- Architectural impact assessment
- Comprehensive code quality checks
- Security vulnerability detection
- Architecture and design analysis
- Optional implementation support with fixes

---

### superpowers - Development Workflow

Advanced development superpowers for orchestrating complex workflows from idea to execution with BDD and Agent Team support.

```bash
claude plugin install superpowers@frad-dotclaude
```

**Key Features:**
- Brainstorming skill for idea clarification and design
- Writing Plans skill for task decomposition with BDD scenario mapping
- Executing Plans skill with serial and parallel Agent Team execution
- Behavior-Driven Development (Red-Green-Refactor cycle)
- Agent Team parallel execution with TaskCreate/TaskUpdate
- Batch execution playbook for independent tasks
- Exit criteria validation for all phases

---

### refactor - Code Refactoring

Code simplification and refactoring with best practices to improve code quality while preserving functionality.

```bash
claude plugin install refactor@frad-dotclaude
```

**Key Features:**
- Automatic code simplification with aggressive mode
- Language-specific references (TypeScript, Python, Go, Swift)
- Next.js optimization patterns (47 specialized patterns)
- Cross-file duplication reduction and consistent patterns
- Legacy code removal
- Semantic search for scope determination
- Preserves functionality while improving clarity

---

### swiftui - SwiftUI Architecture

SwiftUI Clean Architecture reviewer for iOS/macOS development with best practices enforcement.

```bash
claude plugin install swiftui@frad-dotclaude
```

**Key Features:**
- Clean Architecture pattern enforcement
- SwiftUI best practices (2024-2025)
- @Observable and @MainActor validation
- Architecture review and suggestions

---

### claude-config - AI Configuration Generation

Generate comprehensive CLAUDE.md configuration files with environment detection and interactive workflow.

```bash
claude plugin install claude-config@frad-dotclaude
```

**Key Features:**
- 8-phase interactive configuration generation
- Environment detection (Node.js, Python, Rust, Swift, Go, Java, Docker)
- Technology stack selection with package manager preferences
- TDD and Clean Architecture templates
- Git config-based developer profile detection
- Emoji usage policy selection
- Deterministic renderer with backup support

---

### office - Patent Architect

Specialized skills for patent application generation, Feishu document creation, and product requirements documents.

```bash
claude plugin install office@frad-dotclaude
```

**Key Features:**
- Chinese patent application form generation with prior art search
- Automatic prior art search (SerpAPI, Exa.ai, and WebSearch fallback)
- Patent terminology compliance with formal language standards
- Multiple embodiment generation with varying architectures
- Feishu document creation via browser automation
- PRD generation with 2026 best practices and SMART validation
- Hook-based API key validation

---

### plugin-optimizer - Plugin Validation

Validate and optimize Claude Code plugins with agent-based fixes and comprehensive validation.

```bash
claude plugin install plugin-optimizer@frad-dotclaude
```

**Key Features:**
- Plugin manifest validation with JSON output
- Component structure analysis with template validation
- Agent-based optimization with auto-fixes
- Component template validation (agents, skills, commands)
- Tool invocation pattern validation
- Token budget analysis (3-tier progressive disclosure)
- Validation report generation with detailed statistics

---

## Overview

This repository contains a comprehensive set of Claude Code plugins organized into development and productivity categories. Each plugin provides specialized functionality through skills and agents to streamline your coding workflow.

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
├── superpowers/              # Development workflow plugin
├── claude-config/            # AI configuration generation plugin
├── office/                   # Patent architect plugin
├── plugin-optimizer/         # Plugin validation and optimization
└── README.md                 # This file
```

## Plugins

### Development Plugins

#### `git` - Git Automation
Conventional Git automation for commits and repository management.

**Skills:**
| Skill | Description |
|-------|-------------|
| `/git:commit` | Create atomic conventional git commit with AI code quality check |
| `/git:commit-and-push` | Create commits and push to remote repository |
| `/git:update-gitignore` | Update `.gitignore` with Toptal API and OS/language detection |
| `/git:config-git` | Interactive Git configuration with project conventions setup |

**Features:**
- Conventional commit format support with AI code quality check
- Atomic commit creation with Co-Authored-By footer
- Automated gitignore management with OS/language detection
- Pre-commit hook validation
- Project-specific `.claude/git.local.md` configuration generation

---

#### `gitflow` - GitFlow Workflow
GitFlow workflow automation for feature, hotfix, and release branches.

**Skills:**
| Skill | Description |
|-------|-------------|
| `/gitflow:start-feature` | Start new feature branch and push to origin |
| `/gitflow:finish-feature` | Finish feature with tests and changelog update |
| `/gitflow:start-hotfix` | Start hotfix branch with version bump |
| `/gitflow:finish-hotfix` | Finish hotfix with tests, changelog, and tagging |
| `/gitflow:start-release` | Start release branch with version bump |
| `/gitflow:finish-release` | Finish release with tests, changelog, tagging, and GitHub release |
| `/gitflow:gitflow-workflow` | Comprehensive GitFlow workflow guidance |

**Features:**
- Automated branch creation and management
- Proper GitFlow branching strategy
- Automatic merging and tagging
- Semantic versioning
- Pre-finish test validation
- Automatic changelog updates
- GitHub release creation
- Workflow coordination and orchestration

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
| `/refactor:refactor-project` | Project-wide code refactoring with cross-file optimization |

**Features:**
- Automatic code simplification with aggressive mode
- Preserves functionality while improving clarity
- Follows project coding standards
- Language-specific references (TypeScript, Python, Go, Swift)
- Next.js optimization patterns (47 specialized patterns)
- Best practices skill auto-loaded by code-simplifier agent
- Cross-file duplication reduction
- Legacy code removal
- Semantic search for scope determination

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

**Skills:**
| Skill | Description |
|-------|-------------|
| `/github:create-issues` | Create GitHub issues with TDD principles and proper labels |
| `/github:create-pr` | Create pull requests with comprehensive quality validation |
| `/github:resolve-issues` | Resolve issues using isolated worktrees and TDD workflow |

**Features:**
- Automated PR creation with comprehensive quality validation
- Issue creation with TDD principles and proper labels
- TDD workflow with isolated worktrees
- Conventional commits enforcement
- Security scanning for sensitive files
- Quality checks (lint, test, build)
- Auto-closing keywords for issues
- Branch-based decision logic

---

#### `review` - Code Review System
Multi-agent review system for enforcing high code quality.

**Agents:**
| Agent | Description | Model | Color |
|-------|-------------|-------|-------|
| `code-reviewer` | Expert reviewer for correctness, standards, and maintainability | `sonnet` | `blue` |
| `security-reviewer` | Security-focused code review | `sonnet` | `green` |
| `tech-lead-reviewer` | Architecture and design review | `sonnet` | `magenta` |
| `ux-reviewer` | User experience and UI review | `sonnet` | `yellow` |

**Skills:**
| Skill | Description |
|-------|-------------|
| `/review:quick` | Streamlined code review for rapid assessment with selective agents |
| `/review:hierarchical` | Comprehensive multi-stage code review with specialized subagents |

**Features:**
- Selective specialized reviewers (code, security, tech-lead, UX)
- Priority/confidence matrix for findings
- Architectural impact assessment
- Comprehensive code quality checks
- Security vulnerability detection
- Architecture and design analysis
- Optional implementation support with fixes

---

#### `superpowers` - Development Workflow
Advanced development superpowers for orchestrating complex workflows from idea to execution with BDD and Agent Team support.

**Skills:**
| Skill | Description |
|-------|-------------|
| `/superpowers:brainstorming` | Turn rough ideas into implementation-ready designs with BDD specs |
| `/superpowers:writing-plans` | Create executable implementation plans with task decomposition |
| `/superpowers:executing-plans` | Execute plans in serial or parallel with Agent Teams |

**Internal Skills:**
| Skill | Description |
|-------|-------------|
| `behavior-driven-development` | Red-Green-Refactor cycle with Gherkin scenarios |
| `agent-team-driven-development` | Agent Team coordination (Implementer, Reviewer, Architect) |

**Features:**
- End-to-end workflow from idea to shipped code
- Behavior-Driven Development (Red-Green-Refactor)
- Agent Team parallel execution with TaskCreate/TaskUpdate
- Task decomposition and verification with BDD scenario mapping
- Batch execution playbook for independent tasks
- Exit criteria validation for all phases
- Git commit with proper format for designs and plans

---

#### `claude-config` - AI Configuration Generation
Generate comprehensive CLAUDE.md configuration files with environment detection and best practices.

**Skills:**
| Skill | Description |
|-------|-------------|
| `/claude-config:init-config` | Generate `$HOME/.claude/CLAUDE.md` with interactive 8-phase workflow |

**Features:**
- 8-phase interactive configuration generation
- Environment detection (Node.js, Python, Rust, Swift, Go, Java, Docker)
- Technology stack selection with package manager preferences
- TDD and Clean Architecture templates
- Git config-based developer profile detection
- Emoji usage policy selection
- Memory management rules option
- Deterministic renderer with backup support

---

#### `office` - Patent Architect
Specialized skills for patent application generation, Feishu document creation, and product requirements documents.

**Skills:**
| Skill | Description |
|-------|-------------|
| `/office:patent-architect` | Chinese patent application form with prior art search |
| `/office:create-feishu-doc` | Create Feishu documents via browser automation |
| `/office:create-prd` | Create Product Requirements Documents (2026 best practices) |
| `agent-browser` | Browser automation for Feishu UI interaction (internal) |

**Features:**
- Automatic prior art search (SerpAPI, Exa.ai, and WebSearch fallback)
- Chinese patent application form generation with at least 3 embodiments
- Patent terminology compliance with formal language standards
- Multiple embodiment generation (data flow, triggers, architecture variations)
- Feishu document creation with browser automation
- PRD generation with full/brief options and SMART goal validation
- WebSearch integration for comprehensive context gathering

---

#### `plugin-optimizer` - Plugin Validation
Validate and optimize Claude Code plugins against best practices.

**Agents:**
| Agent | Description | Model | Color |
|-------|-------------|-------|-------|
| `plugin-optimizer` | Plugin validation and optimization specialist | `opus` | `cyan` |

**Skills:**
| Skill | Description |
|-------|-------------|
| `/plugin-optimizer:optimize-plugin` | Validate and optimize plugin with agent-based fixes |

**Features:**
- Plugin manifest validation with JSON output
- Component structure analysis with template validation
- Agent-based optimization with auto-fixes
- Component template validation (agents, skills, commands)
- Tool invocation pattern validation
- Token budget analysis (3-tier progressive disclosure)
- Validation report generation with detailed statistics
- README.md updates reflecting current state

---

## Plugin Structure

Each plugin follows Claude Code's standard plugin structure:

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata (required)
├── commands/                # Slash commands (optional, legacy)
│   └── command-name.md
├── agents/                  # Agent definitions (optional)
│   └── agent-name.md
├── skills/                  # Skill definitions (optional)
│   └── skill-name/
│       ├── SKILL.md         # Main skill file
│       └── references/      # Detailed reference materials
├── hooks/                   # Hook configurations (optional)
│   └── hooks.json
├── scripts/                 # Utility scripts (optional)
└── README.md                # Plugin documentation (optional)
```

### Skills vs Commands Architecture

Modern plugins use **skills-based architecture** where each skill is a directory containing:
- `SKILL.md` - Main skill file with YAML frontmatter
- `references/` - Detailed reference materials for progressive disclosure

**Skills registered as commands in plugin.json:**
```json
{
  "commands": [
    "./skills/skill-name/"
  ]
}
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

## Prerequisites

Before installing plugins, ensure you have:

1. **Claude Code CLI installed** - [Download from claude.ai/code](https://claude.ai/code)
2. **Git configured** - Some plugins require git for version control operations
3. **GitHub CLI (optional)** - Required for `github` plugin features

## Verifying Installation

After installing a plugin, verify it's available:

```bash
# List all installed plugins
claude plugin list

# Check plugin status
claude plugin info <plugin-name>@frad-dotclaude
```

## Usage Examples

### Git Workflow

```bash
# Create a conventional commit
/git:commit

# Start a new feature
/gitflow:start-feature user-profile-page

# Finish and merge feature
/gitflow:finish-feature

# Update gitignore
/git:update-gitignore
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

### Development Workflow

```bash
# Brainstorm and design a feature
/superpowers:brainstorming

# Create an implementation plan
/superpowers:writing-plans [design-folder]

# Execute the plan
/superpowers:executing-plans [plan-folder]
```

### Configuration & Optimization

```bash
# Generate AI configuration
/claude-config:init-config

# Optimize plugin
/plugin-optimizer:optimize-plugin
```

### Office & Documentation

```bash
# Generate Chinese patent application
/office:patent-architect

# Create Feishu document
/office:create-feishu-doc

# Create Product Requirements Document
/office:create-prd
```

## Development

### Adding a New Plugin

1. Create plugin directory structure:
   ```bash
   mkdir -p new-plugin/skills new-plugin/agents new-plugin/.claude-plugin
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

### Command Structure (Legacy)

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
argument-hint: [optional-args]
user-invocable: true
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
