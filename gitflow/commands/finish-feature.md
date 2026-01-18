---
allowed-tools: Bash(git:*)
description: Complete and merge current feature development
argument-hint: [feature-name]
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --porcelain`
- Recent commits: !`git log --oneline -5`

## Your task

Complete feature `$ARGUMENTS` development.

1. Confirm branch follows `feature/*` convention and working tree is clean
2. Run tests if available and resolve any failures
3. Merge feature branch into develop
4. Delete feature branch locally and remotely
5. Push updated develop branch
