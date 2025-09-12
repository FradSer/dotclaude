---
allowed-tools: Bash
argument-hint: [feature-name]
description: Start new feature or continue existing feature development
---

## Context

- Current branch: !`git branch --show-current`
- Existing feature branches: !`git branch --list 'feature/*' | sed 's/^..//'`
- Git status: !`git status --porcelain`

## Your task

Start or continue feature development with name: $ARGUMENTS

**Actions to take:**
1. If no feature branches exist: Create new feature branch from develop
2. If one feature branch exists: Switch to existing feature branch
3. If multiple feature branches exist: Show options and let user choose
4. Use kebab-case naming (e.g., `user-authentication`)
5. Publish new feature branch to remote for collaboration
6. Ensure working directory is clean before switching branches

**Required Commit Standards:**
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Follow conventional commits format (feat:, fix:, chore:, etc.)
- Use atomic commits for logical units of work
