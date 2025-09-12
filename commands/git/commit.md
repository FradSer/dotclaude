---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*)
description: Create atomic conventional git commit
model: claude-3-5-haiku-latest
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Recent commits: !`git log --oneline -5`

## Requirements

- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Follow conventional commits format (feat:, fix:, chore:, etc.)
- Use atomic commits for logical units of work

## Your task

Based on the above changes:

1. **Analyze git diff** to identify logical units of work
2. **Split into atomic commits** if multiple logical changes are detected:
   - Each commit should represent one logical unit of work
   - Group related files and changes together
   - Separate different types of changes (feat, fix, chore, docs, etc.)
3. **Create commits sequentially** for each logical unit:
   - Stage only files related to current logical unit
   - Create commit with proper conventional commit message
   - Repeat for remaining logical units
