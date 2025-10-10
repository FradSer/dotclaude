# FradSer's Claude Code Plugin Marketplace ![](https://img.shields.io/badge/A%20FRAD%20PRODUCT-green)

[![Twitter Follow](https://img.shields.io/twitter/follow/FradSer?style=social)](https://twitter.com/FradSer) [![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin%20Marketplace-blue.svg)](https://docs.anthropic.com/en/docs/claude-code/plugins) [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**English | [中文](README.zh-CN.md)**

A comprehensive Claude Code plugin marketplace featuring 5 specialized plugins for code review, Git workflows, GitHub integration, SwiftUI architecture, and development utilities.

## Quick Start

### 1. Add the Marketplace

```bash
# Add FradSer's marketplace
/plugin marketplace add FradSer/dotclaude
```

### 2. Browse and Install Plugins

```bash
# Browse available plugins
/plugin

# Or install specific plugins directly
/plugin install code-review-toolkit@FradSer
/plugin install git-workflow@FradSer
/plugin install github@FradSer
/plugin install swiftui-architecture@FradSer      # For SwiftUI projects
/plugin install utilities@FradSer
```

## Available Plugins

### 🔍 code-review-toolkit [productivity]
**Comprehensive code review toolkit with specialized agents**

**Features:**
- 5 specialized review agents (code, security, tech-lead, UX, simplifier)
- Multi-stage hierarchical review workflow
- Automated refactoring suggestions

**Slash Commands:**
- `/hierarchical` - Multi-agent parallel code review
- `/quick` - Fast two-stage code review
- `/refactor` - Systematic code improvement

**Install:** `/plugin install code-review-toolkit@FradSer`

---

### 🌿 git-workflow [development]
**Git and GitFlow workflow automation**

**Features:**
- Atomic commits with conventional messages
- Complete GitFlow support (feature/release/hotfix)
- Automated commit message generation

**Slash Commands:**
- `/commit`, `/push`, `/commit-and-push` - Git operations
- `/gitignore` - Generate .gitignore files
- `/start-feature`, `/finish-feature` - GitFlow feature workflow
- `/start-release`, `/finish-release` - Release management
- `/start-hotfix`, `/finish-hotfix` - Hotfix workflow

**Install:** `/plugin install git-workflow@FradSer`

---

### 🐙 github [productivity]
**GitHub project management and collaboration**

**Features:**
- Issue management with templates
- PR creation with structured descriptions
- Worktree-based development workflows

**Slash Commands:**
- `/create-pr` - Create pull requests
- `/create-issues` - Generate GitHub issues
- `/resolve-issues` - Smart issue resolution with worktrees

**Install:** `/plugin install github@FradSer`

---

### 📱 swiftui-architecture [development]
**SwiftUI Clean Architecture specialist**

**Features:**
- Clean Architecture compliance verification
- MVVM + SwiftData pattern validation
- 4-layer architecture scoring

**Agents:**
- `@agent-swiftui-clean-architecture-reviewer` - SwiftUI architecture expert

**Install:** `/plugin install swiftui-architecture@FradSer`

---

### 🛠️ utilities [productivity]
**Development workflow utilities**

**Features:**
- Session management and resumption
- Custom command template generation

**Slash Commands:**
- `/continue` - Resume interrupted work sessions
- `/create-command` - Generate new command templates

**Install:** `/plugin install utilities@FradSer`

---

## 📁 Marketplace Structure

```text
dotclaude/
├── .claude-plugin/
│   └── marketplace.json           # Marketplace manifest listing all plugins
├── plugins/
│   ├── code-review-toolkit/       # Code review and quality
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── agents/
│   │   │   ├── code-reviewer.md
│   │   │   ├── security-reviewer.md
│   │   │   ├── tech-lead-reviewer.md
│   │   │   ├── ux-reviewer.md
│   │   │   └── code-simplifier.md
│   │   └── commands/
│   │       ├── hierarchical.md
│   │       ├── quick.md
│   │       └── refactor.md
│   │
│   ├── git-workflow/              # Git and GitFlow
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   └── commands/
│   │       ├── commit.md, push.md, commit-and-push.md, gitignore.md
│   │       └── start-feature.md, finish-feature.md, start-release.md
│   │           finish-release.md, start-hotfix.md, finish-hotfix.md
│   │
│   ├── github/                    # GitHub workflows
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   └── commands/
│   │       ├── create-pr.md
│   │       ├── create-issues.md
│   │       └── resolve-issues.md
│   │
│   ├── swiftui-architecture/      # SwiftUI specialist
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   └── agents/
│   │       └── swiftui-clean-architecture-reviewer.md
│   │
│   └── utilities/                 # Development tools
│       ├── .claude-plugin/
│       │   └── plugin.json
│       └── commands/
│           ├── continue.md
│           └── create-command.md
│
├── CLAUDE.md                      # Development guidelines
└── README.md                      # This file
```

## 🎯 Usage Recommendations

### For Code Quality
Install `code-review-toolkit` for comprehensive code analysis with specialized agents.

### For Git Workflows
Install `git-workflow` for atomic commits and GitFlow management.

### For GitHub Projects
Combine `git-workflow` + `github` for complete GitHub workflow automation.

### For SwiftUI Development
Install `swiftui-architecture` in addition to `code-review-toolkit` for SwiftUI-specific guidance.

### For Maximum Productivity
Install all plugins to unlock the complete development workflow suite.

---

## 📚 Advanced Usage

See [`CLAUDE.md`](CLAUDE.md) for comprehensive development guidelines including:

- **🏗️ Architecture** - SOLID principles, dependency injection, design patterns
- **✨ Code Quality** - Semantic naming, error handling, documentation standards
- **🔄 Development Standards** - TDD, atomic commits, conventional commit messages
- **🛠️ Tech Stack** - Node.js (`pnpm`), Python (`uv`), language-specific best practices

## ❓ FAQ

**Q: Which plugins should I install first?**
A: Start with `code-review-toolkit` and `git-workflow` for essential code quality and version control workflows.

**Q: Can I install only specific plugins?**
A: Yes! Each plugin is independent. Install only what you need for your workflow.

**Q: How do I update plugins?**
A: Use `/plugin update <plugin-name>@FradSer` or reinstall from the marketplace.

**Q: Can I customize these plugins for my team?**
A: Yes - fork the repository, modify plugins, and point your team to your own marketplace.

**Q: What's the difference between agents and slash commands?**
A: Agents are AI specialists you invoke with `@agent-name`. Slash commands are workflow templates you invoke with `/command-name`.

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.
