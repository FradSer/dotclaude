---
name: create-pr
allowed-tools: Task, Bash(gh:*), Bash(git:*)
description: Create comprehensive GitHub pull requests with quality validation
argument-hint: [optional description or issue reference]
user-invocable: true
---

# Create GitHub Pull Request

Execute automated PR creation workflow with comprehensive quality validation and security scanning.

## Context

- Current git status: !`git status`
- Current branch: !`git branch --show-current`
- Unpushed commits: !`git log @{u}..HEAD --oneline 2>/dev/null || git log --oneline -5`
- GitHub authentication: !`gh auth status`
- Repository changes: !`git diff --stat HEAD~1..HEAD 2>/dev/null || echo "No recent changes"`

## Requirements Summary

Ensure repository readiness with clean state and authentication. Complete all quality checks (lint, test, build, security) before PR creation. Link related issues with auto-closing keywords and apply accurate labels. See `references/requirements.md` for complete checklist.

## Phase 1: Validation and Analysis

**Goal**: Validate repository state, analyze changes, and identify blockers.

**Actions**:
1. Verify GitHub authentication from context
2. Check branch status and unpushed commits
3. Analyze commit history for conventional commit compliance
4. Identify changed files and determine PR scope
5. Detect potential blockers (merge conflicts, missing tests, etc.)

## Phase 2: Quality and Security Checks

**Goal**: Execute comprehensive quality validation and security scanning.

**Actions**:
1. Run project-specific quality checks (see `references/quality-validation.md` for commands)
2. Execute security scanning for sensitive files and hardcoded secrets
3. Validate commit message format against standards
4. If checks fail: follow failure resolution process in `references/failure-resolution.md`
5. Re-run all checks until passing

## Phase 3: PR Assembly and Creation

**Goal**: Create pull request with proper structure, metadata, and links.

**Actions**:
1. Identify and link related issues using GitHub CLI
2. Generate PR title (≤70 chars, imperative, no emojis)
3. Assemble PR body following template in `references/pr-structure.md`
4. Apply automated labels based on file changes
5. Create PR using `gh pr create` with all metadata
6. Report final PR URL and status to user

## References

- **Requirements**: `references/requirements.md` - Pre-creation checklist and commit standards
- **Quality Validation**: `references/quality-validation.md` - Node.js/Python validation commands
- **PR Structure**: `references/pr-structure.md` - Title guidelines, body template, labels
- **Failure Resolution**: `references/failure-resolution.md` - Agent collaboration for fixing failures
- **Examples**: `references/examples.md` - Commit message examples
