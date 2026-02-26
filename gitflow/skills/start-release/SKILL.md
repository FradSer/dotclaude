---
name: start-release
allowed-tools: Bash(git:*), Read, Write
description: Begins a new version release using git-flow. This skill should be used when the user asks to "start a release", "create release branch", "prepare a release", "git flow release start", or wants to begin a new version release.
model: haiku
argument-hint: <version>
user-invocable: true
---

## Pre-operation Checks

Verify working tree is clean per `${CLAUDE_PLUGIN_ROOT}/references/invariants.md`.

## Phase 1: Start Release

**Goal**: Create release branch using git-flow-next CLI.

**Actions**:
1. Run `git flow release start $ARGUMENTS`
2. Update version in project files (package.json, Cargo.toml,
   VERSION, etc.)
3. Commit version bump: `chore: bump version to $ARGUMENTS`
   with `Co-Authored-By` footer
4. Push the branch: `git push -u origin release/$ARGUMENTS`

**Note**: CHANGELOG.md is updated during finish-release, not here.
