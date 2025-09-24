# Frad's `.claude` Configuration ![](https://img.shields.io/badge/A%20FRAD%20PRODUCT-green)

[![Twitter Follow](https://img.shields.io/twitter/follow/FradSer?style=social)](https://twitter.com/FradSer) [![Claude Code](https://img.shields.io/badge/Claude%20Code-Configuration-blue.svg)](https://docs.anthropic.com/en/docs/claude-code) [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**English | [中文](README.zh-CN.md)**

A sophisticated multi-agent configuration system for Claude Code featuring specialized agents and structured command templates to accelerate development workflows including code review, refactoring, security audits, architectural guidance, and UX evaluations.

## Quick Start

New to the multi-agent system? Start here:

### 1. Sync Configuration

**Option A: Using DotClaude CLI Tool (Recommended)**
```bash
# Install the dotagent-cli tool
pip install dotagent-cli

# Sync with this repository
dotagent sync --repo FradSer/dotclaude
```

**Option B: Using the Legacy Sync Script**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/FradSer/dotclaude/main/sync-to-github.sh)
```

### 2. Essential Agents
Available in any Claude Code conversation:
- **`@agent-code-reviewer`** - Comprehensive code analysis and best practices
- **`@agent-security-reviewer`** - Security vulnerability assessment
- **`@agent-tech-lead-reviewer`** - Architectural guidance and technical direction
- **`@agent-ux-reviewer`** - User interface and experience evaluation
- **`@agent-code-simplifier`** - Code refactoring and complexity reduction

### 3. Recommended Workflow
**Three-stage quality assurance process:**

1. **🔍 Analysis** - Use `/review/hierarchical` for multi-agent code analysis
2. **📋 Planning** - Use `/gh/create-issues` to create tracked improvement tasks
3. **⚡ Implementation** - Use `/gh/resolve-issues` with smart branch management

> **💡 Best Practice**: Validate Claude's suggestions at each stage to ensure alignment with your project goals.

### 4. Key Commands
Open these command templates in Claude Code:
- **`/review/quick`** - Fast two-stage code review
- **`/git/commit-and-push`** - Structured commit workflow
- **`/continue`** - Resume interrupted work sessions

### 5. Next Steps
- Browse [Agent System](#agent-system) for all available specialists
- Explore [Command Templates](#command-templates) for structured workflows
- Review [Usage Patterns](#usage-patterns) for effective collaboration

---

### Sync Details

<details>
<summary>Synchronization Options (click to expand)</summary>

#### DotClaude CLI Tool (Recommended)
The [dotagent CLI tool](https://github.com/FradSer/dotagent-cli) provides a modern, robust synchronization experience:

```bash
# Basic sync
dotagent sync --repo FradSer/dotclaude

# Include project-specific agents
dotagent sync --repo FradSer/dotclaude --local

# Preview changes before applying
dotagent sync --repo FradSer/dotclaude --dry-run

# Check sync status
dotagent status --repo FradSer/dotclaude
```

**Features:**
- **Universal platform support** - currently supports Claude Code, with planned support for GitHub Copilot, Cursor, and more
- **Bidirectional sync** with intelligent conflict resolution
- **Interactive conflict handling** - choose local, remote, or skip for each item
- **Project-specific agents** - selective sync of `local-agents/` to `.claude/agents/`
- **Safe operations** - preview changes with `--dry-run`
- **Modern CLI** - built with Python, comprehensive error handling

#### Legacy Sync Script
The original bash script is still available:

- Syncs `~/.claude/{agents,commands,CLAUDE.md}` with the same paths in this repo (two-way comparison)
- **Automatic Local Agents Management**: Detects `local-agents/` directory and copies agents to project's `.claude/agents/`
- Automatically detects whether it runs inside this repo or clones into `/tmp/dotclaude-sync`
- Shows a diff for each item and lets you interactively choose: use local, use repo, or skip (supports color diff)
- At the end, you can choose to commit and push (generates a Conventional/Commitizen-style message or falls back to a built-in template)

**Prerequisites:**
- `git`, `curl`, `bash 3.2+` (macOS defaults are fine)
- Optional: `colordiff` (for colored diffs), `claude` CLI (for better commit message generation)

</details>

## 📁 Directory Structure

```text
dotclaude/
├── agents/                    # 🤖 Global agents (all projects)
│   ├── code-reviewer.md
│   ├── code-simplifier.md
│   ├── security-reviewer.md
│   ├── tech-lead-reviewer.md
│   └── ux-reviewer.md
├── local-agents/              # 🎯 Project-specific agents
│   └── swiftui-clean-architecture-reviewer.md
├── commands/                  # ⚡ Workflow templates
│   ├── continue.md
│   ├── create-command.md
│   ├── refactor.md
│   ├── gh/                    # GitHub workflows
│   │   ├── create-issues.md
│   │   ├── create-pr.md
│   │   └── resolve-issues.md
│   ├── git/                   # Git operations
│   │   ├── commit-and-push.md
│   │   ├── commit.md
│   │   ├── gitignore.md
│   │   └── push.md
│   ├── gitflow/               # GitFlow workflows
│   │   ├── finish-feature.md
│   │   ├── finish-hotfix.md
│   │   ├── finish-release.md
│   │   ├── start-feature.md
│   │   ├── start-hotfix.md
│   │   └── start-release.md
│   └── review/                # Code review workflows
│       ├── hierarchical.md
│       └── quick.md
├── CLAUDE.md                  # Development guidelines
├── README.md
├── README.zh-CN.md
└── sync-to-github.sh          # Configuration sync script
```

## 🤖 Agent System

### Global Agents
Universal specialists available in all projects:

| Agent | Purpose | Specialization |
|-------|---------|---------------|
| **`@agent-code-reviewer`** | Code quality analysis | Correctness, maintainability, best practices |
| **`@agent-code-simplifier`** | Refactoring assistance | Complexity reduction, DRY principles, modernization |
| **`@agent-security-reviewer`** | Security assessment | Vulnerability detection, secure coding practices |
| **`@agent-tech-lead-reviewer`** | Technical leadership | Architecture, design patterns, technical direction |
| **`@agent-ux-reviewer`** | User experience audit | Usability, accessibility, interface consistency |

### Local Agents
Project-specific specialists (copied via sync script):

| Agent | Target | Specialization |
|-------|--------|---------------|
| **`@swiftui-clean-architecture-reviewer`** | SwiftUI | Clean Architecture, MVVM, SwiftData patterns |

## ⚡ Command Templates

Structured workflow templates for common development tasks:

### 🔍 Code Review
- **`/review/quick`** - Fast two-stage review process
- **`/review/hierarchical`** - Multi-agent parallel analysis with consolidated results

### 🌿 Git Operations
- **`/git/commit`** - Structured commit workflow with conventional messages
- **`/git/commit-and-push`** - Combined commit and push with validation
- **`/git/push`** - Push with pre-flight checks
- **`/git/gitignore`** - Generate and manage .gitignore files

### 🚀 GitFlow Workflows
- **`/gitflow/start-feature`** - Initialize feature branches
- **`/gitflow/finish-feature`** - Complete and merge features
- **`/gitflow/start-release`** - Prepare release branches
- **`/gitflow/finish-release`** - Finalize and tag releases
- **`/gitflow/start-hotfix`** - Create urgent fix branches
- **`/gitflow/finish-hotfix`** - Deploy critical patches

### 🐙 GitHub Integration
- **`/gh/create-issues`** - Generate issues with templates and labels
- **`/gh/create-pr`** - Create pull requests with structured descriptions
- **`/gh/resolve-issues`** - Smart issue resolution with auto-branching and worktree management

### 🛠️ Development Utilities
- **`/continue`** - Resume interrupted work sessions
- **`/create-command`** - Generate new command templates
- **`/refactor`** - Systematic code improvement checklist

## 💡 Usage Patterns

### Command-Driven Workflows
1. **📋 Open templates** - Use command files as interactive checklists in Claude Code
2. **🎯 Follow workflows** - Each template provides structured, step-by-step guidance
3. **🤝 Maintain consistency** - Standardized approaches across team members and projects

### Agent Collaboration

**Sequential Reviews** (thorough analysis):
```bash
@agent-code-reviewer → @agent-security-reviewer → @agent-tech-lead-reviewer
```

**Parallel Specialization** (targeted expertise):
```bash
@agent-ux-reviewer        # UI/UX focused
@agent-security-reviewer  # Security focused
@agent-code-simplifier    # Refactoring focused
```

**Project-Specific** (after sync):
```bash
@swiftui-clean-architecture-reviewer  # SwiftUI projects
```

### 🤝 Collaboration Philosophy

**Human-AI Partnership**
Claude Code serves as your specialized development partner, providing expert analysis and recommendations while you maintain decision-making authority and project context.

**GitHub Integration**
The `gh` CLI creates seamless workflows where issues, pull requests, and commits become structured documentation, capturing both human decisions and AI insights.

**Validation-Driven Development**
Each automation step includes human validation points, ensuring AI suggestions align with project goals and constraints.

---

## 📚 Advanced Usage

See [`CLAUDE.md`](CLAUDE.md) for comprehensive development guidelines including:

- **🏗️ Architecture** - SOLID principles, dependency injection, design patterns
- **✨ Code Quality** - Semantic naming, error handling, documentation standards
- **🔄 Development Standards** - TDD, atomic commits, conventional commit messages
- **🛠️ Tech Stack** - Node.js (`pnpm`), Python (`uv`), language-specific best practices

## ❓ FAQ

**Q: Is the sync script interactive?**
A: Yes - you choose local vs. repo for each item and decide whether to commit/push at the end.

**Q: How do I get colored diffs?**
A: Install `colordiff` - the script auto-detects and uses it when available.

**Q: Can I customize agents for my project?**
A: Yes - add project-specific agents to `local-agents/` and run the sync script.

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.
