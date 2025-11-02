---
description: Start new hotfix or continue existing hotfix development
trigger: /start-hotfix
argumentHint: "[hotfix description]"
---

## Context

- Current branch: `git branch --show-current`
- Existing hotfix branches: List all hotfix branches
- Latest tag: `git tag --list --sort=-creatordate | head -1`
- Current version from main: Inspect version files on the main branch
- Git status: `git status --porcelain`

## Requirements

- Hotfix branches must use the `hotfix/` prefix and represent patch-level fixes.
- Increment the patch version automatically if none is provided and update version files.
- Keep scope limited to critical production fixes before publishing.
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Commit message body must use normal text formatting (proper capitalization and punctuation)
- Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Use atomic commits for logical units of work

## Your Task

1. Decide whether to create a new `hotfix/$ARGUMENTS` branch from `main` or resume an existing hotfix branch.
2. Update version metadata and changelog entries to reflect the new patch before development begins.
3. Switch to the hotfix branch, ensure the workspace is ready, and push the branch for collaboration if newly created.
