---
allowed-tools: Bash
argument-hint: [version]
description: Complete and merge current release development
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --porcelain`
- Recent commits: !`git log --oneline -5`
- Test commands available: !`([ -f package.json ] && echo "npm/pnpm/yarn") || ([ -f Cargo.toml ] && echo "cargo") || ([ -f pyproject.toml ] && echo "pytest/uv") || ([ -f go.mod ] && echo "go test") || echo "no standard test framework detected"`
- Current version: !`([ -f package.json ] && grep '"version"' package.json) || ([ -f Cargo.toml ] && grep '^version' Cargo.toml) || ([ -f pyproject.toml ] && grep '^version' pyproject.toml) || echo "no version found"`

## Your task

Complete and merge release development: $ARGUMENTS

**Actions to take:**
1. Validate current branch is a release branch (`release/*`)
2. Ensure all changes are committed
3. Run tests if available before finishing
4. Update changelog if exists
5. Finish release using git flow (merges to main, creates tag, back-merges to develop)
6. Push all changes and tags to origin
7. Create GitHub release
8. Handle merge conflicts if they occur

**Manual recovery if git flow fails:**
- Merge release to main and create tag
- Back-merge to develop
- Clean up release branch
- Push changes and create GitHub release

**Required Commit Standards:**
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Follow conventional commits format (feat:, fix:, chore:, etc.)
- Use atomic commits for logical units of work
