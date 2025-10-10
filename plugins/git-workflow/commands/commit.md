---
allowed-tools: Task, Bash(git:*)
description: Create atomic conventional git commit
model: claude-3-5-haiku-latest
---

## Context

- Current git status: !`git status`
- Staged changes: !`git diff --cached`
- Unstaged changes: !`git diff`
- Recent commits: !`git log --oneline -5 2>/dev/null || echo "No commits yet"`

## Requirements

- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Use atomic commits for logical units of work

## Your task

**IMPORTANT: You MUST use the Task tool to complete ALL tasks.**

Based on the above changes:

1. **Analyze git diff** to identify logical units of work
2. **Split into atomic commits** if multiple logical changes are detected:
   - Each commit should represent one complete logical change
   - Group related files that belong to the same feature or fix
   - Separate different change types (feat, fix, chore, docs, etc.) into distinct commits
3. **Create commits sequentially** for each logical unit:
   - Stage only files related to current logical unit
   - Create commit with proper conventional commit message
   - Repeat for remaining logical units
