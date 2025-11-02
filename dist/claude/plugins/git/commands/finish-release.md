---
allowed-tools: Task, Bash
description: Complete and merge current release development
model: claude-haiku-4-5-20251001
---

## Context

- Current branch: !`git branch --show-current`
- Existing release branches: !`git branch --list 'release/*' | sed 's/^..//'`
- Git status: !`git status --porcelain`
- Recent commits: !`git log --oneline -5`
- Test commands available: Detect available testing frameworks for this project
- Current version: Check version information in project configuration files

## Requirements

- Release branches must follow the `release/<version>` naming pattern and encode the target semantic version.
- Update changelog and README documentation before completing the release.
- Execute the full Git Flow release finish sequence (merge to `main`, tag, merge back to `develop`).
- **Use atomic commits for logical units of work**: Each commit should represent one complete, cohesive change.
- Title: entirely lowercase, <50 chars, imperative mood (e.g., "add", "fix", "update"), conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Body: blank line after title, ≤72 chars per line, must start with uppercase letter, standard capitalization and punctuation. Describe what changed and why, not how.
- Footer (optional): Must start with uppercase letter, standard capitalization. Reference issues/PRs (Closes #123, Fixes #456, Linked to PR #789). Use BREAKING CHANGE: prefix for breaking changes.

### Examples

```
feat(auth): add google oauth login flow

- Introduce Google OAuth 2.0 for user sign-in
- Add backend callback endpoint `/auth/google/callback`
- Update login UI with Google button and loading state

Add a new authentication option improving cross-platform
sign-in.

Closes #42. Linked to #38 and PR #45
```

```
fix(api): handle null payload in session refresh

- Validate payload before accessing `user.id`
- Return proper 400 response instead of 500
- Add regression test for null input

Prevents session refresh crash when token expires.

Fixes #105
```

```
feat(auth): migrate to oauth 2.0

- Replace basic auth with OAuth 2.0 flow
- Update authentication middleware
- Add token refresh endpoint

BREAKING CHANGE: Authentication API now requires OAuth 2.0 tokens. Basic auth is no longer supported.

Closes #120. Linked to #115 and PR #122
```

## Your Task

**IMPORTANT: You MUST use the Task tool to complete ALL tasks.**

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
