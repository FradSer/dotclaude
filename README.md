# Frad's .claude

Claude Code configuration with specialized AI agents and command templates.

## Quick Sync

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/FradSer/dotclaude/main/sync-to-github.sh)
```

## Agents

### code-reviewer
Comprehensive code analysis for correctness, best practices, and maintainability.

### code-simplifier
Refactoring specialist for improving readability and reducing complexity.

### security-reviewer
Cybersecurity expert for vulnerability assessment and secure coding practices.

### tech-lead-reviewer
Senior technical leadership perspective for architectural decisions and complex challenges.

### ux-reviewer
User experience specialist for interface evaluation and usability assessment.

## Commands

### Review Workflows
- `commands/review/quick.md` - Two-stage review for rapid assessment
- `commands/review/hierarchical.md` - Multi-stage review for complex changes

### Fix Operations
- `commands/fix/quick.md` - Rapid assessment and targeted fixes
- `commands/fix/code-quality.md` - Code quality improvements
- `commands/fix/security.md` - Security-focused fixes
- `commands/fix/ui.md` - User interface improvements

### Git Operations
- `commands/git/commit.md` - Standard commit workflow
- `commands/git/commit-and-push.md` - Commit and push workflow
- `commands/git/push.md` - Push changes to remote
- `commands/git/release.md` - Release management

### Other
- `commands/continue.md` - Continue previous work
- `commands/refactoring.md` - Code refactoring workflow
- `commands/gh/create-issues.md` - GitHub issue creation

## CLAUDE.md

Development guidelines and standards:

### Architecture
- Follow SOLID principles
- Prefer composition over inheritance, dependency injection for testability
- Use repository pattern for data access, strategy pattern for algorithmic variations

### Code Quality
- Use descriptive names, avoid abbreviations and magic numbers
- Keep functions under 20 lines, files concise
- Handle all error scenarios with meaningful messages
- Comment "why" not "what"

### Development Standards
- Search first when uncertain, write tests for core functionality
- Update documentation when modifying code
- Prefer pnpm for Node.js projects
- Commit titles: lowercase, max 50 characters
- Merge PRs with merge commits
- No emojis, avoid hardcoding secrets
- Make atomic git commits for each completed feature stage and push 
