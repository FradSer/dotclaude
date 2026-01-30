---
name: start-feature
allowed-tools: Bash(git:*), Read, Skill
description: Start new feature branch
model: haiku
argument-hint: [feature-name]
user-invocable: true
---

## Initialization

Load the `gitflow:gitflow-workflow` skill using the Skill tool to access GitFlow workflow capabilities.

## Phase 1: Context Gathering

**Goal**: Gather current git state and prepare for feature branch creation.

**Actions**:
1. Run `git status` to check working tree status
2. Run `git branch` to list existing feature branches
3. Identify the base branch for the active workflow (usually `develop` for Classic GitFlow, or `main` for GitHub Flow)

## Phase 2: Branch Preparation

**Goal**: Normalize feature name and validate branch configuration.

**Actions**:
1. Normalize the provided feature name from `$ARGUMENTS` to `$FEATURE_NAME` using the normalization procedure defined in the `gitflow-workflow` skill references (strip `feature/` prefix if present, convert to kebab-case)
2. Validate the base branch exists and is up to date

## Phase 3: Branch Creation and Push

**Goal**: Create or resume the feature branch and sync with remote.

**Actions**:
1. Create or checkout `feature/$FEATURE_NAME` from the base branch
2. Push the branch to origin if newly created
