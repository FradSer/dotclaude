# Requirements

## Repository and Authentication

- Ensure the repository is clean, authenticated, and ready for PR submission.
- Complete lint, test, build, and security checks before creating the PR.
- Link related issues and apply accurate labels for traceability.

## Commit Message Standards

- **Use atomic commits for logical units of work**: Each commit should represent one complete, cohesive change.
- Title: entirely lowercase, <50 chars, imperative mood (e.g., "add", "fix", "update"), conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
  - Scope (optional): lowercase noun, 1-2 words. Must match existing scopes in git history.
- Body: blank line after title, ≤72 chars per line, must start with uppercase letter, standard capitalization and punctuation. Describe what changed and why, not how.
- Footer (optional): Must start with uppercase letter, standard capitalization. Reference issues/PRs (Closes #123, Fixes #456, Linked to PR #789). Use BREAKING CHANGE: prefix for breaking changes.

## Pre-Creation Checklist

- Repository state validated and clean
- All quality checks passed (lint, test, build)
- Security scan completed without issues
- Related issues identified and linked
- Proper branch naming and commit messages following standards
