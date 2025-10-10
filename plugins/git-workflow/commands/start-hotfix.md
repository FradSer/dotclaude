---
allowed-tools: Task, Bash
argument-hint: [version]
description: Start new hotfix or continue existing hotfix development
---

## Context

- Current branch: !`git branch --show-current`
- Existing hotfix branches: List all hotfix branches
- Latest tag: !`git tag --list --sort=-creatordate | head -1`
- Current version from main: Check version information in main branch configuration files
- Git status: !`git status --porcelain`

## Your task

**IMPORTANT: You MUST use the Task tool to complete ALL tasks.**

Start or continue hotfix development with version: $ARGUMENTS

**Actions to take:**
1. If no hotfix branches exist: Create new hotfix branch from main
2. If hotfix branch exists: Switch to existing hotfix branch
3. Auto-increment patch version from latest tag (1.2.3 → 1.2.4) if no version specified
4. Update version files (package.json, Cargo.toml, pyproject.toml, etc.)
5. Focus on critical bug fixes only
6. Keep changes minimal and targeted

**Required Commit Standards:**
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Use atomic commits for logical units of work
