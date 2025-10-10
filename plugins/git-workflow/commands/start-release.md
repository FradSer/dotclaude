---
allowed-tools: Task, Bash
argument-hint: [version]
description: Start new release or continue existing release development
---

## Context

- Current branch: !`git branch --show-current`
- Existing release branches: !`git branch --list 'release/*' | sed 's/^..//'`
- Latest tag: !`git tag --list --sort=-creatordate | head -1`
- Recent commits for version detection: !`git log $(git describe --tags --abbrev=0 2>/dev/null || echo)..develop --oneline --grep="feat\|fix\|BREAKING" 2>/dev/null || git log develop --oneline --grep="feat\|fix\|BREAKING"`
- Current version: Check version information in project configuration files

## Your task

**IMPORTANT: You MUST use the Task tool to complete ALL tasks.**

Start or continue release development with version: $ARGUMENTS

**Actions to take:**
1. If no release branches exist: Create new release branch from develop
2. If release branch exists: Switch to existing release branch
3. Use latest tag as base version for semantic version bump
4. Determine semantic version bump based on conventional commits:
   - `feat!`/`fix!` or BREAKING CHANGE → major bump
   - `feat:` commits → minor bump
   - `fix:` commits → patch bump
5. Update version files (package.json, Cargo.toml, pyproject.toml, etc.)
6. Publish release branch to remote for collaboration

**Required Commit Standards:**
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Use atomic commits for logical units of work
