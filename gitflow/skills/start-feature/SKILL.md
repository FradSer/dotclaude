---
name: start-feature
allowed-tools: Bash(git:*)
description: Start new feature branch
model: haiku
argument-hint: <feature-name>
user-invocable: true
---

## Phase 1: Start Feature

**Goal**: Create feature branch using git-flow-next CLI.

**Actions**:
1. Run `git flow feature start $ARGUMENTS`
2. Push the branch to origin: `git push -u origin feature/$ARGUMENTS`
