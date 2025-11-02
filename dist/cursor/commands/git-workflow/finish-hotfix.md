---
description: Complete and merge current hotfix development
trigger: /finish-hotfix
argumentHint: "[version]"
---

## Context

- Current branch: `git branch --show-current`
- Git status: `git status --porcelain`
- Recent commits: `git log --oneline -5`
- Test commands available: Detect available testing frameworks for this project
- Current version: Check version information in project configuration files

## Requirements

- Hotfix branches must follow the `hotfix/*` naming convention and remain narrowly scoped.
- Update version metadata and changelog entries as part of the hotfix release.
- Finish the Git Flow hotfix procedure (merge to `main` and `develop`, create release tag).
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Commit message body must use normal text formatting (proper capitalization and punctuation)
- Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Use atomic commits for logical units of work

## Your Task

1. Validate the branch name, ensure the working tree is clean, and confirm all hotfix commits are present.
2. Execute the relevant tests, increment the patch version if required, and refresh changelog entries before finalizing.
3. Complete the hotfix workflow—merge into `main` and `develop`, create and push tags, publish the GitHub release summary, and remove the hotfix branch locally and remotely.
