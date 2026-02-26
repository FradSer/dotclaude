---
name: start-hotfix
allowed-tools: Bash(git:*), Read, Write
description: Begins a hotfix for a production issue using git-flow. This skill should be used when the user asks to "start a hotfix", "create hotfix branch", "fix a critical bug", "git flow hotfix start", or wants to begin a hotfix.
model: haiku
argument-hint: <version>
user-invocable: true
---

## Pre-operation Checks

Verify working tree is clean per `${CLAUDE_PLUGIN_ROOT}/references/invariants.md`.

## Phase 1: Start Hotfix

**Goal**: Create hotfix branch using git-flow-next CLI.

**Actions**:
1. Run `git flow hotfix start $ARGUMENTS`
2. Update version in project files (package.json, Cargo.toml,
   VERSION, etc.)
3. Commit version bump: `chore: bump version to $ARGUMENTS`
   with `Co-Authored-By` footer
4. Push the branch: `git push -u origin hotfix/$ARGUMENTS`
