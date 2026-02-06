---
name: start-feature
allowed-tools: Bash(git:*)
description: This skill should be used when the user asks to "start a feature", "create feature branch", "begin new feature", "git flow feature start", or wants to start working on a new feature branch.
model: haiku
argument-hint: <feature-name>
user-invocable: true
---

## Pre-operation Checks

Verify working tree is clean per `${CLAUDE_PLUGIN_ROOT}/references/invariants.md`.

## Phase 1: Start Feature

**Goal**: Create feature branch using git-flow-next CLI.

**Actions**:
1. Run `git flow feature start $ARGUMENTS`
2. Push the branch to origin: `git push -u origin feature/$ARGUMENTS`
