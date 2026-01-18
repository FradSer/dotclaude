---
allowed-tools: Bash(git:*)
description: Start new feature or continue existing feature development
argument-hint: [feature-name]
---

## Context

- Current branch: !`git branch --show-current`
- Existing feature branches: !`git branch --list 'feature/*' | head -10`
- Git status: !`git status --porcelain`

## Your task

Start or resume feature development for `$ARGUMENTS`.

1. Ensure working directory is clean
2. Create `feature/$ARGUMENTS` branch from develop (or switch to existing)
3. Push new branch to origin for collaboration

Feature branches use kebab-case names under `feature/` prefix.
