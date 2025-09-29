---
allowed-tools: Bash(gh:*), Bash(git:*), Bash(cd:*), Bash(mkdir:*), Task
description: Resolve GitHub issues using isolated worktrees and TDD
---

## Context

- Current git status: !`git status`
- Current branch: !`git branch --show-current`
- Existing worktrees: !`git worktree list`
- Open issues: !`gh issue list --state open --limit 10`
- GitHub authentication: !`gh auth status`

## Requirements

- Use isolated worktrees for development
- Follow TDD approach and protected PR workflow
- Issue resolution commit standards:
  - Commit message title must be entirely lowercase
  - Title must be less than 50 characters
  - Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
  - Use atomic commits for logical units of work
  - Include issue reference in commit body when relevant
- Protected branches require PR + review + CI

## Your task

**IMPORTANT: You MUST use the Task tool to complete ALL tasks.**

Resolve GitHub issues using systematic worktree workflow:

### Workflow Overview

1. **Select issue** - View open issues by priority and choose next one
2. **Create worktree** - Set up isolated workspace with feature branch
3. **TDD implementation** - Plan, implement, test, review with agents
4. **PR creation** - Run quality checks, push branch, create PR
5. **Cleanup** - Remove worktree after merge

### Implementation Steps

1. **Branch Detection**: Check if on main/develop or existing worktree
2. **Issue Selection**: View open issues and select one to resolve
3. **Worktree Creation**: Set up isolated development environment
4. **TDD Implementation**: Follow red-green-refactor cycle with agent assistance
5. **Quality Validation**: Run tests and checks before PR creation
6. **PR Creation**: Create pull request with proper linking
7. **Cleanup**: Remove worktree after merge

### TDD Process

1. **Planning** - Use @tech-lead-reviewer sub agent for strategy
2. **Red** - Add failing test that reproduces the issue
3. **Green** - Implement minimal fix to make test pass
4. **Review** - Use specialized agents:
   - code-reviewer for comprehensive review
   - security-reviewer for sensitive code
   - ux-reviewer for UI changes
5. **Refactor** - Use @code-simplifier sub agent while keeping tests green
6. **Commit** - Create atomic commits following conventional format

### Worktree Management

Based on current branch and existing worktrees:
- **On main/develop**: Create new worktree or continue existing one
- **In worktree**: Continue with TDD implementation
- **After completion**: Clean up worktree and return to main branch

### Quality Standards

- Run project-specific quality checks (lint, test, build)
- All tests must pass before PR creation
- Follow atomic commit requirements
- Use proper PR linking with auto-closing keywords (`fixes`, `closes`, `resolves`)

### Branch Naming Convention

Generate descriptive branch names:
- `feature/123-webxr-fallback` - New functionality
- `fix/456-auth-redirect` - Bug fixes
- `refactor/789-api-cleanup` - Code improvements
