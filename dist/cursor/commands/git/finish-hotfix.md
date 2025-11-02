---
description: Complete and merge current hotfix development
trigger: /finish-hotfix
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

1. Validate the branch name, ensure the working tree is clean, and confirm all hotfix commits are present.
2. Execute the relevant tests, increment the patch version if required, and refresh changelog entries before finalizing.
3. Complete the hotfix workflow—merge into `main` and `develop`, create and push tags, publish the GitHub release summary, and remove the hotfix branch locally and remotely.
