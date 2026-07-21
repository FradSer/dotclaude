# Auto-Closing Keywords

`Closes`/`Fixes`/`Resolves #N` in a PR body or commit message tells GitHub to close the linked issue when the PR merges. This is the single authoritative reference for all `/github:*` skills.

## CRITICAL LIMITATION

**Auto-closing keywords only close the linked issue when the PR merges into the repository's default branch** (the repository's configured default, e.g. `main`). If the PR targets a non-default branch (e.g. `develop` in Git Flow), GitHub **ignores** these keywords and the issue will NOT close automatically — it must be closed manually, and you MUST warn the user that auto-close will not fire.

## Keyword Table

| Keyword | Variants | Behavior |
|---------|----------|----------|
| close | close, closes, closed | PR merges into default branch → issue closes |
| fix | fix, fixes, fixed | PR merges into default branch → issue closes |
| resolve | resolve, resolves, resolved | PR merges into default branch → issue closes |

The keyword is case-insensitive and accepts a `#`-prefixed issue number (`Closes #456`) or a full URL.

## Rules

- **PR-scoped issue targeting the default branch**: use an auto-closing keyword.
- **PR-scoped issue targeting a non-default branch**: WARN the user that auto-close will not fire; link the issue manually via GitHub UI or `gh issue edit` after merge.
- **Epic issues** (issues tracking multiple PRs): do NOT use auto-closing — link manually, since no single PR closes an epic.

## Who enforces this

- **`/github:create-issues`**: warn at issue-creation time when the issue is PR-scoped and the eventual PR base may be non-default.
- **`/github:create-pr`**: warn at PR-creation time (Phase 3, target base branch validation) when the PR targets a non-default branch.
- **`/github:resolve-issues`**: surfaced via the `/github:create-pr` handoff — do not re-warn here; create-pr owns the warning at PR-creation time.

This file replaces the per-skill copies that had drifted between "main/master", "default branch", and "must be closed manually" — the canonical phrasing is "default branch" everywhere.
