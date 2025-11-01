---
description: Create atomic conventional git commit and push to remote
trigger: /commit-and-push
---

## Context

- Current git status: `git status`
- All changes: `git diff HEAD`

## Requirements

- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Commit message body must use normal text formatting (proper capitalization and punctuation)
- Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Use atomic commits for logical units of work

## Your task

Based on the above changes:

1. **Analyze git diff** to identify logical units of work
2. **Split into atomic commits** if multiple logical changes are detected:
   - Each commit should represent one complete logical change that will be pushed
   - Group related files that belong to the same feature or fix for remote sync
   - Separate different change types (feat, fix, chore, docs, etc.) before pushing
3. **Create commits sequentially** for each logical unit:
   - Stage only files related to current logical unit
   - Create commit with proper conventional commit message
   - Repeat for remaining logical units
4. **Push to remote repository** after all commits are created:
   - Push the current branch to the remote repository
   - If the branch doesn't have a remote tracking branch set up, create it with `-u` flag
