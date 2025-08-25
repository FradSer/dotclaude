# GitHub Issue Creation

Create issues following TDD principles and Conventional Commits with proper labels, scope, and auto-closing keywords.

## Prerequisites
- `gh` CLI authenticated
- Conventional commits (≤50 chars subject, ≤72 chars body)
- Protected branches require PR + review + CI
- No direct pushes to main/develop

## Decision Logic

**Branch-based decision tree** (oneOf pattern for mutually exclusive paths):

- **On main/develop**: Create issue directly
- **On PR branch**: Ask "Must this be fixed before merge?"
  - **Yes**: Comment in PR with detailed context and reasoning, don't create issue
  - **No**: Create new issue for later with clear justification for scope separation

## Issue Types
1. **Epic issues**: multi-PR initiatives (no auto-close keywords)  
2. **PR-scoped issues**: single PR resolution (use auto-close keywords)

Follow TDD: issue → test → code → PR → merge

## Epic Issues (Multi-PR)

For large, cross-cutting initiatives spanning multiple PRs/repos.

**Structure**: Problem, Scope, Acceptance Criteria, Out of Scope
**Labels**: `enhancement`, `priority:*`, area labels
**Title**: ≤70 chars, imperative, no emojis

**Linking**:
```bash
# Link sub-issue to epic
gh issue comment <epic_number> --body "Sub-issue: #<sub_issue_number>"

# Link PR to epic  
gh pr comment <pr_number> --body "Part of epic #<epic_number>"
```

## PR-Scoped Issues (Single PR)

**Structure**: Problem, Steps to Reproduce, Expected vs Actual, Environment, Acceptance Criteria
**Labels**: `bug` or `enhancement`, `priority:*`
**Title**: ≤70 chars, imperative, no emojis

**Auto-closing setup**: Use keywords (`fixes #<number>`) in PR body when resolving this issue.

## Issues from PR Review

For non-blocking feedback that's out-of-scope or larger than current PR.

**Structure**: Context, Acceptance Criteria, Priority
**Labels**: `enhancement`, `priority:*`, `help wanted`
**Title**: ≤70 chars, imperative, no emojis

**Cross-reference**: Link issue to original PR via comment: `gh issue comment <issue_number> --body "From PR #<pr_number> review"`

## Labels & Prioritization

**Label Setup**:
```bash
# Ensure priority labels exist before creating issues
gh label create "priority:high" --description "High priority - this sprint" --color "d73a4a" || true
gh label create "priority:medium" --description "Medium priority - next sprint" --color "fbca04" || true  
gh label create "priority:low" --description "Low priority - backlog" --color "0075ca" || true
```
**Required Labels**:
- **Priority**: `priority:high` (this sprint), `priority:medium` (next sprint), `priority:low` (backlog)
- **Type**: `bug`, `enhancement`, `documentation`, `question`

**Optional Labels**: `help wanted`, `good first issue`, `duplicate`, `invalid`, `wontfix`

## Quick Reference

**Auto-closing keywords**: `close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved`

**Key principles**:
- Issues before code (TDD)
- Epic issues: manual linking, no auto-close keywords
- PR-scoped issues: designed for auto-close keywords
- Clear titles ≤70 chars, no emojis