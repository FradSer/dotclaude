---
allowed-tools: Bash
argument-hint: [version]
description: Start new hotfix or continue existing hotfix development
---

## Context

- Current branch: !`git branch --show-current`
- Existing hotfix branches: !`git branch --list 'hotfix/*' | sed 's/^..//'`
- Current version from main: !`(git show main:package.json 2>/dev/null | grep '"version"') || (git show main:Cargo.toml 2>/dev/null | grep '^version') || (git show main:pyproject.toml 2>/dev/null | grep '^version') || echo "no version found on main"`
- Git status: !`git status --porcelain`

## Your task

Start or continue hotfix development with version: $ARGUMENTS

**Actions to take:**
1. If no hotfix branches exist: Create new hotfix branch from main
2. If hotfix branch exists: Switch to existing hotfix branch
3. Auto-increment patch version (1.2.3 → 1.2.4) if no version specified
4. Update version files (package.json, Cargo.toml, pyproject.toml, etc.)
5. Focus on critical bug fixes only
6. Keep changes minimal and targeted

**Required Commit Standards:**
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Use atomic commits for logical units of work
