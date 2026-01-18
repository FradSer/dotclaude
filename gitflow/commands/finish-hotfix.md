---
allowed-tools: Bash(git:*), Bash(gh:*)
description: Complete and merge current hotfix
argument-hint: [version]
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --porcelain`
- Recent commits: !`git log --oneline -5`
- Latest tag: !`git tag --list --sort=-creatordate | head -1`

## Your task

Complete the current hotfix.

1. Validate branch follows `hotfix/*` pattern and working tree is clean
2. Run tests and resolve any failures
3. Update version metadata and changelog
4. Merge hotfix into main with `--no-ff`
5. Tag the merge commit with version (e.g., `v1.2.1`)
6. Merge main back into develop
7. Delete hotfix branch locally and remotely
8. Push main, develop, and tags to origin
9. Create GitHub release from the new tag
