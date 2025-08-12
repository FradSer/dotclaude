# Frad's `.claude` Multi-Agent System ![](https://img.shields.io/badge/A%20FRAD%20PRODUCT-WIP-yellow)

[![Twitter Follow](https://img.shields.io/twitter/follow/FradSer?style=social)](https://twitter.com/FradSer) [![Claude Code](https://img.shields.io/badge/Claude%20Code-Configuration-blue.svg)](https://docs.anthropic.com/en/docs/claude-code) [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A sophisticated multi-agent configuration system for Claude Code that provides specialized agents and command templates to accelerate code review, refactoring, security audits, tech-lead guidance, and UX evaluations.

## Quick Sync

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/FradSer/dotclaude/main/sync-to-github.sh)
```

What the script does:
- Syncs `~/.claude/{agents,commands,CLAUDE.md}` with the same paths in this repo (two-way comparison).
- Automatically detects whether it runs inside this repo or clones into `/tmp/dotclaude-sync`.
- Shows a diff for each item and lets you interactively choose: use local, use repo, or skip (supports color diff).
- At the end, you can choose to commit and push (generates a Conventional/Commitizen-style message or falls back to a built-in template).

Prerequisites:
- `git`, `curl`, `bash 3.2+` (macOS defaults are fine).
- Optional: `colordiff` (for colored diffs), `claude` CLI (for better commit message generation).

## Directory Structure

```text
dotclaude/
  - agents/
    - code-reviewer.md
    - code-simplifier.md
    - security-reviewer.md
    - tech-lead-reviewer.md
    - ux-reviewer.md
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

## Specialized Agents

Each agent provides domain-specific expertise for comprehensive code analysis:

| Agent | Purpose | Focus Areas |
|-------|---------|-------------|
| **code-reviewer** | Comprehensive code review | Correctness, error handling, maintainability, best practices |
| **code-simplifier** | Refactoring & optimization | Readability, complexity reduction, DRY principles |
| **security-reviewer** | Security audit & hardening | AuthN/AuthZ, input validation, dependency scanning |
| **tech-lead-reviewer** | Architectural guidance | System design, technical direction, risk assessment |
| **ux-reviewer** | User experience evaluation | Usability heuristics, accessibility standards, UI consistency |

## Command Templates

Structured workflows for common development tasks:

### 🔍 Review Workflows
- **`review/quick.md`** - Two-stage rapid review process
- **`review/hierarchical.md`** - Multi-layered parallel reviews with consolidated output

### 🛠️ Fix Operations
- **`fix/code-quality.md`** - Code quality improvements (naming, complexity, performance)
- **`fix/security.md`** - Security vulnerability identification and remediation
- **`fix/ui.md`** - UI/UX consistency and usability enhancements

### 📦 Git Operations
- **`git/commit.md`** - Structured commit workflow
- **`git/commit-and-push.md`** - Combined commit and push operations
- **`git/push.md`** - Push with validation checks
- **`git/release.md`** - Git-flow release management

### 🔧 GitHub Integration
- **`gh/create-issues.md`** - Issue creation with templates
- **`gh/resolve-issues.md`** - Issue resolution workflows

### 🔄 Development Utilities
- **`continue.md`** - Resume interrupted work sessions
- **`refactor.md`** - Systematic code refactoring checklist

## Usage Patterns

### Agent Invocation
```
@code-reviewer     # Comprehensive code analysis
@security-reviewer # Security-focused audit  
@tech-lead-reviewer # Architectural guidance
@ux-reviewer       # User experience evaluation
@code-simplifier   # Refactoring assistance
```

### Command-Driven Workflows
1. **Open command templates** - Use `commands/*.md` files as interactive checklists
2. **Follow structured processes** - Each template guides you through specific workflows
3. **Maintain consistency** - Standardized approaches across team members

### Multi-Agent Collaboration
```bash
# Example: Comprehensive review pipeline
@code-reviewer → @security-reviewer → @tech-lead-reviewer
```

### Sync Management
- Run Quick Sync periodically to maintain alignment with the repository
- Interactive diff resolution for local vs. remote changes
- Automatic commit message generation with Conventional style

## Development & Commit Conventions (Key Excerpts)

See `CLAUDE.md` for full details. Key points:

- Architecture: Follow SOLID; prefer composition over inheritance; use dependency injection for testability; Repository for data access and Strategy for algorithmic variations.
- Code quality: Semantic naming; avoid magic numbers; keep functions small; cover error scenarios with meaningful messages; comment on "why" rather than "what".
- Standards: Search first when unsure; write tests for core functionality; update docs with code changes; prefer `pnpm` for Node.js projects.
- Commit conventions (this repo):
  - Commit messages must be in English only.
  - Commitizen/Conventional style (e.g., `feat(scope): subject`).
  - Title lowercase, length ≤ 50 characters, focused on what changed.
  - Atomic commits; no emojis; PRs use merge commits.

Note: If any item in `CLAUDE.md` conflicts with this section, this section takes precedence (e.g., the 50-character title limit).

## FAQ

- Is the sync script non-interactive? It is interactive: choose local vs. repo per item and decide whether to commit and push at the end.
- No colored diffs? Optionally install `colordiff`; the script will auto-detect and use it.

## License

MIT License
