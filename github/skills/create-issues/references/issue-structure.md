# Issue Structure Requirements

## Title
- ≤70 chars
- Imperative mood
- No emojis

## Labels
- Include priority labels (priority:high, priority:medium, priority:low)
- Include type labels (bug, feature, enhancement, documentation, etc.)

## Body
- Problem description
- Acceptance criteria
- Context and background

## Auto-Closing Keywords
- Use keywords (`fixes`, `closes`, `resolves`) for PR-scoped issues
- Example: "Closes #123" in PR description will auto-close issue #123
- Do NOT use auto-close keywords for epic issues

## Key Principles

- Follow TDD: issue → test → code → PR → merge.
- Epic issues: manual linking, no auto-close keywords.
- PR-scoped issues: designed for auto-close keywords.
- Clear, actionable descriptions with proper context.
