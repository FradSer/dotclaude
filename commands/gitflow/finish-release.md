---
allowed-tools: Task, Bash
argument-hint: [version]
description: Complete and merge current release development
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --porcelain`
- Recent commits: !`git log --oneline -5`
- Test commands available: Detect available testing frameworks for this project
- Current version: Check version information in project configuration files

## Your task

**IMPORTANT: You MUST use the Task tool to complete ALL tasks.**

Complete and merge release development: $ARGUMENTS

**Actions to take:**
1. Validate current branch is a release branch (`release/*`)
2. Ensure all changes are committed
3. Run tests if available before finishing
4. Update changelog if exists
5. Update all README files (README*.*, README.*.*, etc.) if they exist
6. Finish release workflow (merges to main, creates tag, back-merges to develop)
7. Push all changes and tags to origin
8. Create GitHub release
9. Handle merge conflicts if they occur

**Manual recovery if workflow fails:**
- Merge release to main and create tag
- Back-merge to develop
- Clean up release branch
- Push changes and create GitHub release

**Required Commit Standards:**
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Use atomic commits for logical units of work
