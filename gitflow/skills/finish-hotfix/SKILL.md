---
name: finish-hotfix
allowed-tools: Bash(git:*), Read, Write
description: Finalizes a hotfix and merges it into main and develop using git-flow. This skill should be used when the user asks to "finish a hotfix", "merge hotfix branch", "complete hotfix", "git flow hotfix finish", or wants to finalize a hotfix.
model: haiku
argument-hint: [version]
user-invocable: true
---

## Pre-operation Checks

Verify working tree is clean and current branch matches `hotfix/*` per `${CLAUDE_PLUGIN_ROOT}/references/invariants.md`.

## Phase 1: Identify Version

**Goal**: Determine hotfix version from current branch or argument.

**Actions**:
1. If `$ARGUMENTS` provided, use it as version (strip 'v' prefix if present)
2. Otherwise, extract from current branch: `git branch --show-current` (strip `hotfix/` prefix)
3. Store clean version without 'v' prefix (e.g., "1.0.1")

## Phase 2: Pre-finish Checks

**Goal**: Run tests before finishing.

**Actions**:
1. Identify test commands (check package.json, Makefile, etc.)
2. Run tests if available; exit if tests fail

## Phase 3: Update Changelog

**Goal**: Generate changelog from commits.

**Actions**:
1. Get previous tag: `git tag --sort=-v:refname | head -1`
2. Collect commits per `${CLAUDE_PLUGIN_ROOT}/references/changelog-generation.md`
3. Update CHANGELOG.md per `${CLAUDE_PLUGIN_ROOT}/examples/changelog.md`
4. Commit: `chore: update changelog for v$VERSION` with `Co-Authored-By` footer

## Phase 4: Finish Hotfix

**Goal**: Complete hotfix using git-flow-next CLI.

**Actions**:
1. Run `git flow hotfix finish $VERSION --tagname "v$VERSION" -m "Release v$VERSION"`
2. Verify current branch: `git branch --show-current` (should be on develop)
3. Push all: `git push origin main develop --tags`
