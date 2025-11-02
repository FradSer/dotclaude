---
allowed-tools: Task, Bash(git:*)
description: Create atomic conventional git commit and push to remote
model: claude-haiku-4-5-20251001
---

## Requirements

- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Commit message body must use normal text formatting (proper capitalization and punctuation)
- Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Use atomic commits for logical units of work

- Pushes must target the current branch on the remote; create a tracking branch when necessary using `git push -u`.

## Your Task

**IMPORTANT: You MUST use the Task tool to complete ALL tasks.**

1. Review the diff overview (e.g. `git status`, `git diff --stat`) to determine discrete logical units of work.
2. For each unit, stage the relevant files and create a conventional commit.
3. After committing all units, push the branch to the remote, configuring the upstream if it does not exist.
