---
name: create-issues
allowed-tools: Task, Bash(gh:*), Bash(git:*)
description: Creates GitHub issues following test-driven development principles and proper labeling conventions. This skill should be used when the user asks to "create an issue", "file a bug", or needs to document new requirements, epics, or PR-scoped tasks.
argument-hint: [description]
user-invocable: true
---

# Create GitHub Issues

Execute automated GitHub issue creation workflow for $ARGUMENTS following TDD principles and conventional commit standards.

## Context

- Current git status: !`git status`
- Current branch: !`git branch --show-current`
- Open issues: !`gh issue list --state open --limit 10`
- GitHub authentication: !`gh auth status`

## Requirements Summary

Follow TDD principles, conventional commits, and protected branch workflows. Use proper labels, auto-closing keywords, and atomic commits. See `references/requirements.md` for complete standards.

## Phase 1: Repository Analysis

**Goal**: Assess repository state and determine issue scope and type.

**Actions**:
1. Analyze current branch from context (main/develop vs PR branch)
2. Review open issues to identify duplicates or related work
3. Determine issue type (epic, PR-scoped, or review) based on `$ARGUMENTS` complexity
4. Apply branch-based decision logic from `references/decision-logic.md`

## Phase 2: Issue Creation

**Goal**: Create GitHub issue with proper structure, labels, and links.

**Actions**:
1. Create or verify required priority labels exist (see `references/decision-logic.md` for commands)
2. Draft issue following structure requirements in `references/issue-structure.md`
3. Apply appropriate labels (priority, type)
4. Add auto-closing keywords if PR-scoped issue (NOT for epics)
5. Link to related issues or epics if applicable

## Phase 3: Documentation and Handoff

**Goal**: Document decisions and communicate follow-up actions.

**Actions**:
1. Document branch strategy decision and rationale
2. Report created issue number and URL to user
3. If on PR branch and blocking: add detailed comment to PR instead of creating issue
4. Share next steps (create PR, assign to team member, etc.)

## References

- **Requirements**: `references/requirements.md` - Full TDD and commit standards
- **Decision Logic**: `references/decision-logic.md` - Branch-based decisions and issue types
- **Issue Structure**: `references/issue-structure.md` - Title, labels, body, auto-closing
- **Examples**: `references/examples.md` - Commit message examples
