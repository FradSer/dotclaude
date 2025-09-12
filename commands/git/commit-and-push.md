---
allowed-tools: Bash(git:*)
description: Create atomic conventional git commit and push to remote
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
4. **Push to remote repository** after all commits are created:
   - Push the current branch to the remote repository
   - If the branch doesn't have a remote tracking branch set up, create it with `-u` flag
