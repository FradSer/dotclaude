---
allowed-tools: Task, Bash
description: Start new release or continue existing release development
model: claude-haiku-4-5-20251001
---

## Context

- Current branch: !`git branch --show-current`
- Existing release branches: !`git branch --list 'release/*' | sed 's/^..//'`
- Latest tag: !`git tag --list --sort=-creatordate | head -1`
- Conventional commit scan: !`git log $(git describe --tags --abbrev=0 2>/dev/null || echo)..develop --oneline --grep="feat\|fix\|BREAKING" 2>/dev/null || git log develop --oneline --grep="feat\|fix\|BREAKING"`
- Current version: Inspect project configuration files

## Requirements

- Release branches must use the `release/` prefix and reflect the target semantic version.
- Determine the semantic version bump using conventional commit history (breaking → major, feat → minor, fix → patch).
- Update version metadata (package manifests, changelog) and publish the branch to origin.
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

1. Decide whether to create a new `release/<version>` branch from `develop` or resume an existing release branch.
2. Calculate the next semantic version based on commit history and update version files accordingly.
3. Switch to the release branch, push it to origin if newly created, and prepare it for stabilization work.
