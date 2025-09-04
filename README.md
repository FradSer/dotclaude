# Frad's `.claude` ![](https://img.shields.io/badge/A%20FRAD%20PRODUCT-WIP-yellow)

[![Twitter Follow](https://img.shields.io/twitter/follow/FradSer?style=social)](https://twitter.com/FradSer) [![Claude Code](https://img.shields.io/badge/Claude%20Code-Configuration-blue.svg)](https://docs.anthropic.com/en/docs/claude-code) [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**English | [中文](README-zh.md)**

A sophisticated multi-agent configuration system for Claude Code that provides specialized agents and command templates to accelerate code review, refactoring, security audits, tech-lead-guidance, and UX evaluations.

## Quick Start

New to the multi-agent system? Start here:

### 1. Sync Configuration
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/FradSer/dotclaude/main/sync-to-github.sh)
```

### 2. Basic Agent Usage
In any Claude Code conversation:
- `@agent-code-reviewer` - Review your code for issues
- `@agent-security-reviewer` - Check for security vulnerabilities
- `@agent-ux-reviewer` - Evaluate user interface designs

### 3. Best Practice Workflow in `claude`
Three-stage collaborative process for comprehensive code quality:

1. **Hierarchical Review** - Use `/review/hierarchical` for thorough multi-agent analysis
   - *Review and validate Claude's analysis before proceeding*

2. **Issue Creation** - Use `/gh/create-issues` to create GitHub issues for tracking improvements  
   - *Check and refine the issues Claude suggests before creating*

3. **Quality Implementation** - Use `/gh/resolve-issues` with intelligent branch detection, AI-generated names, and worktree management
   - *Automatically detects existing worktrees and offers continuation options*
   - *Uses AI to generate concise, descriptive branch names*
   - *Review Claude's code suggestions and adapt them to your context*

Each step requires engineer validation to ensure Claude's output aligns with project goals and constraints. See [Collaboration Philosophy](#collaboration-philosophy) for partnership principles.

### 4. Essential Commands
Open these templates as checklists in Claude Code:
- **Quick review**: `commands/review/quick.md`
- **Fix issues**: `commands/fix/code-quality.md`
- **Commit changes**: `commands/git/commit-and-push.md`

### 5. Next Steps
- Browse [Specialized Agents](#specialized-agents) for all available experts
- Explore [Command Templates](#command-templates) for structured workflows
- Set up [Multi-Agent Collaboration](#multi-agent-collaboration) pipelines

---

### Sync Details

<details>
<summary>What the sync script does (click to expand)</summary>

- Syncs `~/.claude/{agents,commands,CLAUDE.md}` with the same paths in this repo (two-way comparison)
- **Automatic Local Agents Management**: Detects `local-agents/` directory and copies agents to project's `.claude/agents/`
- Automatically detects whether it runs inside this repo or clones into `/tmp/dotclaude-sync`
- Shows a diff for each item and lets you interactively choose: use local, use repo, or skip (supports color diff)
- At the end, you can choose to commit and push (generates a Conventional/Commitizen-style message or falls back to a built-in template)

**Prerequisites:**
- `git`, `curl`, `bash 3.2+` (macOS defaults are fine)
- Optional: `colordiff` (for colored diffs), `claude` CLI (for better commit message generation)

</details>

## Directory Structure

```text
dotclaude/
  - agents/                    # Global agents (available in all projects)
    - code-reviewer.md
    - code-simplifier.md
    - security-reviewer.md
    - tech-lead-reviewer.md
    - ux-reviewer.md
  - local-agents/              # Local agents (project-specific)
    - swiftui-clean-architecture-reviewer.md
  - commands/
    - continue.md
    - fix/
      - code-quality.md
      - security.md
      - ui.md
    - gh/
      - create-issues.md
      - resolve-issues.md
    - git/
      - commit-and-push.md
      - commit.md
      - push.md
      - release.md
    - refactor.md
    - review/
      - hierarchical.md
      - quick.md
  - CLAUDE.md
  - README.md
  - sync-to-github.sh
```

## Agent System

### Global Agents
Universal specialized agents available in all projects, stored in `agents/` directory:

| Agent | Purpose | Focus Areas |
|-------|---------|-------------|
| **agent-code-reviewer** | Comprehensive code review | Correctness, error handling, maintainability, best practices |
| **agent-code-simplifier** | Refactoring & optimization | Readability, complexity reduction, DRY principles |
| **agent-security-reviewer** | Security audit & hardening | AuthN/AuthZ, input validation, dependency scanning |
| **agent-tech-lead-reviewer** | Architectural guidance | System design, technical direction, risk assessment |
| **agent-ux-reviewer** | User experience evaluation | Usability heuristics, accessibility standards, UI consistency |

### Local Agents
Project-specific specialized agents stored in `local-agents/` directory, copied to project's `.claude/agents/` via sync script:

| Agent | Purpose | Focus Areas | Target Projects |
|-------|---------|-------------|----------------|
| **swiftui-clean-architecture-reviewer** | SwiftUI Clean Architecture review | Layer separation, MVVM patterns, SwiftData integration, @Observable patterns | SwiftUI projects |

## Command Templates

Structured workflows for common development tasks:

### Review Workflows
- **`/review/quick`** - Two-stage rapid review process
- **`/review/hierarchical`** - Multi-layered parallel reviews with consolidated output

### Fix Operations
- **`/fix/code-quality`** - Code quality improvements (naming, complexity, performance)
- **`/fix/security`** - Security vulnerability identification and remediation
- **`/fix/ui`** - UI/UX consistency and usability enhancements

### Git Operations
- **`/git/commit.md`** - Structured commit workflow
- **`/git/commit-and-push`** - Combined commit and push operations
- **`/git/push`** - Push with validation checks
- **`/git/release`** - Git-flow release management

### GitHub Integration
- **`/gh/create-issues`** - Issue creation with templates
- **`/gh/resolve-issues`** - Smart issue resolution with branch detection, AI-generated names, and worktree continuation

### Development Utilities
- **`/continue`** - Resume interrupted work sessions
- **`/refactor`** - Systematic code refactoring checklist

## Usage Patterns

### Command-Driven Workflows
1. **Open command templates** - Use `commands/*.md` files as interactive checklists
2. **Follow structured processes** - Each template guides you through specific workflows
3. **Maintain consistency** - Standardized approaches across team members

### Agent Invocation

**Global Agents** (available in any project):
```
@agent-code-reviewer     # Comprehensive code analysis
@agent-security-reviewer # Security-focused audit
@agent-tech-lead-reviewer # Architectural guidance
@agent-ux-reviewer       # User experience evaluation
@agent-code-simplifier   # Refactoring assistance
```

**Local Agents** (must be copied to project via sync script first):
```
@swiftui-clean-architecture-reviewer # SwiftUI Clean Architecture review
```

### Multi-Agent Collaboration
```bash
# Example: Comprehensive review pipeline
@agent-code-reviewer → @agent-security-reviewer → @agent-tech-lead-reviewer
```

### Collaboration Philosophy

**Claude Code as Your Development Partner**

Treat Claude Code as an excellent colleague who collaborates asynchronously. This partnership provides specialized expertise and quality assurance while requiring your validation at each step to ensure alignment with project goals.

**GitHub as a Collaboration Platform**

GitHub with `gh` CLI creates seamless integration between Claude Code and project management. Issues, pull requests, and commits become structured documentation, transforming development into thoughtful technical writing where both human decisions and AI insights are captured and trackable.

### Sync Management
- Run Quick Sync periodically to maintain alignment with the repository
- Interactive diff resolution for local vs. remote changes
- Automatic commit message generation with Conventional style

---

## Advanced Usage

See `CLAUDE.md` for full development guidelines. Key points:

**Architecture**
- Follow SOLID principles; prefer composition over inheritance
- Use dependency injection for testability
- Repository pattern for data access, Strategy pattern for algorithmic variations

**Code Quality**
- Semantic naming; avoid magic numbers; keep functions small
- Cover error scenarios with meaningful messages
- Comment on "why" rather than "what"

**Development Standards**
- Search first when unsure; write tests for core functionality
- Update docs with code changes; prefer `pnpm` for Node.js projects
- Commit messages: English only, Conventional style (≤50 chars)
- Atomic commits; no emojis; PRs use merge commits

## FAQ

- Is the sync script non-interactive? It is interactive: choose local vs. repo per item and decide whether to commit and push at the end.
- No colored diffs? Optionally install `colordiff`; the script will auto-detect and use it.

## License

MIT License
