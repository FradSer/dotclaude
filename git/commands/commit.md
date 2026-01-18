---
allowed-tools: Bash(git:*)
description: Create atomic conventional git commit
---

## Context

- Git status: !`git status`
- Staged changes: !`git diff --cached --stat`
- Unstaged changes: !`git diff --stat`
- Recent commits: !`git log --oneline -5`

## Your task

Based on the above changes, create atomic commits following conventional commit format.

1. Analyze pending changes to identify coherent logical units of work
2. Stage relevant files for each logical unit
3. Create a commit with a conventional message (lowercase title < 50 chars, body describes what/why)
4. Repeat until all changes are committed

Follow project commit conventions defined in `CLAUDE.md`.
