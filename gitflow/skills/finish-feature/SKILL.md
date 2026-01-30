---
name: finish-feature
allowed-tools: Bash(git:*), Read, Skill
description: Complete and merge feature branch
model: haiku
argument-hint: [feature-name]
user-invocable: true
---

## Initialization

Load the `gitflow:gitflow-workflow` skill using the Skill tool to access GitFlow workflow capabilities.

## Phase 1: Context Validation

**Goal**: Gather and validate current branch state before merging.

**Actions**:
1. Run `git status` to check working tree status
2. Run `git log --oneline -10` to review recent commits
3. Normalize the provided feature name from `$ARGUMENTS` to `$FEATURE_NAME` (strip `feature/` prefix if present, convert to kebab-case)
4. Validate current branch follows `feature/*` convention and working tree is clean

## Phase 2: Testing

**Goal**: Run automated tests to ensure code quality before merge.

**Actions**:
1. Identify test commands available in the repository (check for test scripts in package.json, Makefile, etc.)
2. Run tests if available
3. If tests fail, report the failures and exit without merging; the user must fix issues first

## Phase 3: Changelog Update

**Goal**: Document changes in the Unreleased section of CHANGELOG.

**Actions**:
1. Ensure changes are documented in the `[Unreleased]` section of `CHANGELOG.md` following `${CLAUDE_PLUGIN_ROOT}/examples/changelog.md`:
   - Use standard Keep a Changelog sections (Added, Changed, Deprecated, Removed, Fixed, Security)
   - Write entries in present/imperative tense using user-facing language
   - Include sufficient context to understand impact; merge repetitive items
2. Commit any CHANGELOG updates using conventional commit format and MUST include the `Co-Authored-By` footer

## Phase 4: Branch Merge and Cleanup

**Goal**: Merge feature branch and clean up local and remote branches.

**Actions**:
1. Identify target integration branch for the active workflow (often `develop`)
2. Merge `feature/$FEATURE_NAME` into the integration branch (often with `--no-ff`)
3. Push the integration branch with merged changes
4. Delete `feature/$FEATURE_NAME` locally and remotely (skip deletion if the branch is shared or the user requests to keep it)
