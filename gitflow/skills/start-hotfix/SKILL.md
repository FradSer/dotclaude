---
name: start-hotfix
allowed-tools: Bash(git:*), Read, Write, Skill
description: Start new hotfix branch
model: haiku
argument-hint: [hotfix-name]
user-invocable: true
---

## Initialization

Load the `gitflow:gitflow-workflow` skill using the Skill tool to access GitFlow workflow capabilities.

## Phase 1: Context Gathering

**Goal**: Gather current git state and version information for hotfix preparation.

**Actions**:
1. Run `git status` to check working tree status
2. Run `git branch` to list existing hotfix branches
3. Run `git tag --sort=-v:refname` to identify the latest version tag
4. Identify version files in the repository using patterns from the `gitflow-workflow` skill references

## Phase 2: Version Analysis

**Goal**: Normalize hotfix name and determine version increment.

**Actions**:
1. Normalize the provided hotfix name from `$ARGUMENTS` to `$HOTFIX_NAME` using the normalization procedure defined in the `gitflow-workflow` skill references (strip `hotfix/` prefix if present, convert to kebab-case)
2. Identify the production base branch for the active workflow (usually `main` for Classic GitFlow, or `production` for GitLab Flow)
3. Determine the next patch version if the repo uses SemVer and tags

## Phase 3: Branch Creation

**Goal**: Create or resume the hotfix branch from production base.

**Actions**:
1. Create or checkout `hotfix/$HOTFIX_NAME` from the production base branch
2. Validate the branch was created successfully

## Phase 4: Version Update and Push

**Goal**: Update version files and sync with remote.

**Actions**:
1. Increment the patch version in version files (if the repo uses SemVer + tags)
2. Commit version changes if updates were made
3. Push the branch to origin if newly created
