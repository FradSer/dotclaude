---
allowed-tools: Task
description: Streamlined code review for rapid assessment and targeted feedback
argument-hint: [files-or-directories]
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --porcelain`
- Base branch: !`(git show-branch | grep '*' | grep -v "$(git rev-parse --abbrev-ref HEAD)" | head -1 | sed 's/.*\[\([^]]*\)\].*/\1/' | sed 's/\^.*//' 2>/dev/null) || echo "develop"`
- Changes since base: !`BASE=$(git merge-base HEAD develop 2>/dev/null || git merge-base HEAD main 2>/dev/null) && git log --oneline $BASE..HEAD`
- Files changed since base: !`BASE=$(git merge-base HEAD develop 2>/dev/null || git merge-base HEAD main 2>/dev/null) && git diff --name-only $BASE..HEAD`
- Test commands available: !`([ -f package.json ] && echo "npm/pnpm/yarn test") || ([ -f Cargo.toml ] && echo "cargo test") || ([ -f pyproject.toml ] && echo "pytest/uv run pytest") || ([ -f go.mod ] && echo "go test") || echo "no standard test framework detected"`

## Requirements

- Use **@tech-lead-reviewer** — architectural impact assessment — to scope the review and decide which specialized agents are required.
- Launch only the necessary specialized reviews to minimize turnaround time.
- Summarize results by priority (Critical → High → Medium → Low) and confidence (High → Medium → Low).
- Offer optional implementation support and ensure resulting commits follow conventional standards.
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

1. Run an initial assessment with **@tech-lead-reviewer** — architectural impact assessment — to gauge architectural, security, and UX risk, and determine if a deeper review is needed.
2. Trigger the relevant specialized reviews via the Task tool, gather targeted feedback, and resolve conflicting recommendations.
3. Present a concise summary, ask whether the user wants fixes implemented, and if confirmed, apply changes, refactor with **@code-simplifier** — code simplification and optimization —, test, and stage commits before reporting outcomes.

### Targeted Review Flow

- **Selective Agents**: 
  - **@code-reviewer** — logic correctness, tests, error handling.
  - **@security-reviewer** — authentication, data protection, validation.
  - **@ux-reviewer** — usability and accessibility (skip if purely backend/CLI).
- **Results Analysis**: Organize findings using the priority/confidence matrix and provide actionable steps.
- **Optional Implementation**: Execute requested fixes, optimize the code, rerun tests, and prepare commits that adhere to the standards fragment.
- **Closure**: Push updates if changes were made and confirm review completion with the user.
