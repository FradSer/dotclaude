---
allowed-tools: Bash
argument-hint: [feature-name]
description: Complete and merge current feature development
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --porcelain`
- Recent commits: !`git log --oneline -5`
- Test commands available: !`([ -f package.json ] && echo "npm/pnpm/yarn") || ([ -f Cargo.toml ] && echo "cargo") || ([ -f pyproject.toml ] && echo "pytest/uv") || ([ -f go.mod ] && echo "go test") || echo "no standard test framework detected"`

## Your task

Complete and merge feature development: $ARGUMENTS

**Actions to take:**
1. Validate current branch is a feature branch (`feature/*`)
2. Ensure all changes are committed (no uncommitted changes)
3. Run tests if available before merging
4. Merge feature branch to develop using gitflow workflow
5. Delete the feature branch locally and remotely
6. Push develop branch to origin
7. Handle any merge conflicts that arise

**Required Commit Standards:**
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Use atomic commits for logical units of work
