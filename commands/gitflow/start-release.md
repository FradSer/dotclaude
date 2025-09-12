---
allowed-tools: Bash
argument-hint: [version]
description: Start new release or continue existing release development
---

## Context

- Current branch: !`git branch --show-current`
- Existing release branches: !`git branch --list 'release/*' | sed 's/^..//'`
- Recent commits for version detection: !`git log $(git describe --tags --abbrev=0)..develop --oneline --grep="feat\|fix\|BREAKING"`
- Current version: !`([ -f package.json ] && grep '"version"' package.json) || ([ -f Cargo.toml ] && grep '^version' Cargo.toml) || ([ -f pyproject.toml ] && grep '^version' pyproject.toml) || echo "no version found"`

## Your task

Start or continue release development with version: $ARGUMENTS

**Actions to take:**
1. If no release branches exist: Create new release branch from develop
2. If release branch exists: Switch to existing release branch
3. Determine semantic version bump based on conventional commits:
   - `feat!`/`fix!` or BREAKING CHANGE → major bump
   - `feat:` commits → minor bump
   - `fix:` commits → patch bump
4. Update version files (package.json, Cargo.toml, pyproject.toml, etc.)
5. Publish release branch to remote for collaboration

**Required Commit Standards:**
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Follow conventional commits format (feat:, fix:, chore:, etc.)
- Use atomic commits for logical units of work
