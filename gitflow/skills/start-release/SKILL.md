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

## Phase 0: Validate Version

**Goal**: Ensure `$ARGUMENTS` is a valid next version.

**Actions**:
1. Run `git tag --sort=-v:refname | head -1` to get the latest tag (e.g., `v1.8.0`)
2. Strip the leading `v` prefix for comparison
3. If `$ARGUMENTS` is not strictly greater than the latest tag version (semver), abort and tell the user: "Version $ARGUMENTS is not greater than the current latest tag <latest>. Please provide a higher version."
4. If no tags exist, skip this check

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
