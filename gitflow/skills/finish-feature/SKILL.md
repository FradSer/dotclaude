---
name: finish-feature
allowed-tools: Bash(git:*), Read, Write
description: This skill should be used when the user asks to "finish a feature", "merge feature branch", "complete feature", "git flow feature finish", or wants to finalize and merge a feature branch into develop.
model: haiku
argument-hint: [feature-name]
user-invocable: true
---

## Pre-operation Checks

Verify working tree is clean and current branch matches `feature/*` per `${CLAUDE_PLUGIN_ROOT}/references/invariants.md`.

## Phase 1: Identify Feature

**Goal**: Determine feature name from current branch or argument.

**Actions**:
1. If `$ARGUMENTS` provided, use it as feature name
2. Otherwise, extract from current branch: `git branch --show-current` (strip `feature/` prefix)

## Phase 2: Pre-finish Checks

**Goal**: Run tests before finishing.

**Actions**:
1. Identify test commands (check package.json, Makefile, etc.)
2. Run tests if available; exit if tests fail

## Phase 3: Update Changelog

**Goal**: Document changes in CHANGELOG.md.

**Actions**:
1. Ensure changes are in `[Unreleased]` section per `${CLAUDE_PLUGIN_ROOT}/examples/changelog.md`
2. Commit CHANGELOG updates with `Co-Authored-By` footer

## Phase 4: Finish Feature

**Goal**: Complete feature using git-flow-next CLI.

**Actions**:
1. Run `git flow feature finish $FEATURE_NAME`
2. Verify current branch: `git branch --show-current` (should be on develop)
3. Push develop: `git push origin develop`
