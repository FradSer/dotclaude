---
allowed-tools: Bash(git:*)
description: Start new hotfix or continue existing hotfix
argument-hint: [hotfix-name]
---

## Context

- Current branch: !`git branch --show-current`
- Existing hotfix branches: !`git branch --list 'hotfix/*' | head -5`
- Latest tag: !`git tag --list --sort=-creatordate | head -1`
- Git status: !`git status --porcelain`

## Your task

Start or resume hotfix for `$ARGUMENTS`.

1. Ensure working directory is clean
2. Create `hotfix/$ARGUMENTS` branch from main (or switch to existing)
3. Increment patch version and update version files
4. Push hotfix branch to origin

Hotfix branches use `hotfix/` prefix for critical production fixes.
