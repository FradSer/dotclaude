---
allowed-tools: Task, Bash
argument-hint: [version]
description: Complete and merge current hotfix development
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --porcelain`
- Recent commits: !`git log --oneline -5`
- Test commands available: Detect available testing frameworks for this project
- Current version: Check version information in project configuration files

## Your task

**IMPORTANT: You MUST use the Task tool to complete ALL tasks.**

Complete and merge hotfix development: $ARGUMENTS

**Actions to take:**
1. Validate current branch is a hotfix branch (`hotfix/*`)
2. Ensure all changes are committed
3. Run tests if available before finishing
4. Update changelog if exists
5. Finish hotfix workflow (merges to main and develop, creates tag)
6. Push all changes and tags to origin
7. Create GitHub release with hotfix details
8. Handle merge conflicts if they occur
9. Keep fixes critical and minimal

**Required Commit Standards:**
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Use atomic commits for logical units of work
