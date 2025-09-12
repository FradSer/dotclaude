---
allowed-tools: Bash(gh:*), Bash(git:*)
description: Create GitHub issues with TDD principles and proper labels
---

## Context

- Current git status: !`git status`
- Current branch: !`git branch --show-current`
- Open issues: !`gh issue list --state open --limit 10`
- GitHub authentication: !`gh auth status`

## Requirements

- Follow TDD principles and Conventional Commits
- Use proper labels, scope, and auto-closing keywords
- Protected branches require PR + review + CI
- No direct pushes to main/develop

## Your task

Based on the current repository state and $ARGUMENTS, create GitHub issues following best practices:

### Decision Logic

**Branch-based decision tree**:
- **On main/develop**: Create issue directly
- **On PR branch**: Ask "Must this be fixed before merge?"
  - **Yes**: Comment in PR with detailed context and reasoning, don't create issue
  - **No**: Create new issue for later with clear justification for scope separation

### Issue Types

1. **Epic issues**: Multi-PR initiatives (no auto-close keywords)
2. **PR-scoped issues**: Single PR resolution (use auto-close keywords)
3. **Review issues**: Non-blocking feedback from PR reviews

### Issue Creation Process

1. **Analyze context** from git status and existing issues
2. **Determine issue type** based on scope and complexity
3. **Create proper labels** if they don't exist:
   ```bash
   gh label create "priority:high" --description "High priority - this sprint" --color "d73a4a" || true
   gh label create "priority:medium" --description "Medium priority - next sprint" --color "fbca04" || true
   gh label create "priority:low" --description "Low priority - backlog" --color "0075ca" || true
   ```
4. **Create issue** with proper structure and labels
5. **Link related items** if applicable

### Issue Structure Requirements

- **Title**: ≤70 chars, imperative, no emojis
- **Labels**: Include priority and type labels
- **Body**: Problem description, acceptance criteria, context
- **Auto-closing**: Use keywords (`fixes`, `closes`, `resolves`) for PR-scoped issues

### Key Principles

- Follow TDD: issue → test → code → PR → merge
- Epic issues: manual linking, no auto-close keywords
- PR-scoped issues: designed for auto-close keywords
- Clear, actionable descriptions with proper context
