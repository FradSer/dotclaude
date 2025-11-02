---
description: Complete and merge current release development
trigger: /finish-release
---

## Context

- Current branch: `git branch --show-current`
- Existing release branches: `git branch --list 'release/*' | sed 's/^..//'`
- Git status: `git status --porcelain`
- Recent commits: `git log --oneline -5`
- Test commands available: Detect available testing frameworks for this project
- Current version: Check version information in project configuration files

## Requirements

- Release branches must follow the `release/<version>` naming pattern and encode the target semantic version.
- Update changelog and README documentation before completing the release.
- Execute the full Git Flow release finish sequence (merge to `main`, tag, merge back to `develop`).
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Commit message body must use normal text formatting (proper capitalization and punctuation)
- Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Use atomic commits for logical units of work

## Your Task

1. Validate branch naming, ensure a clean working tree, and confirm all tests succeed.
2. Merge the release branch into `main` with `--no-ff`, tag the merge commit using the encoded version, and merge `main` back into `develop`.
3. Delete the release branch locally and remotely, push `main`, `develop`, and tags to origin, create the GitHub release from the new tag, and handle conflicts as needed.

### Manual Recovery (if workflow fails)

- `git checkout main`
- `git merge --no-ff release/x.x.x`
- `git tag -a vx.x.x -m "Release x.x.x"`
- `git checkout develop`
- `git merge --no-ff main`
- `git branch -d release/x.x.x && git push origin --delete release/x.x.x`
- `git push origin main develop --tags`
- Create the GitHub release
