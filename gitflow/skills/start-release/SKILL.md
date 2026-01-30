---
name: start-release
allowed-tools: Bash(git:*), Read, Write, Skill
description: Start new release branch
model: haiku
argument-hint: [version]
user-invocable: true
---

## Initialization

Load the `gitflow:gitflow-workflow` skill using the Skill tool to access GitFlow workflow capabilities.

## Phase 1: Context Gathering

**Goal**: Gather git state, version information, and commit history for release planning.

**Actions**:
1. Run `git status` to check working tree status
2. Run `git branch` to list existing release branches
3. Run `git tag --sort=-v:refname` to identify the latest version tag
4. Run `git log` to review recent commit history for version calculation
5. Identify version files in the repository using patterns from the `gitflow-workflow` skill references

## Phase 2: Version Determination

**Goal**: Normalize and determine the release version.

**Actions**:
1. Normalize the provided version from `$ARGUMENTS` to `$RELEASE_VERSION` using the normalization procedure defined in the `gitflow-workflow` skill references (accept v1.2.3 or 1.2.3, normalize to 1.2.3)
2. If no version provided, calculate semantic version from conventional commits using the rules in `gitflow-workflow` skill references
3. Validate the determined version follows SemVer format

## Phase 3: Branch Creation

**Goal**: Create or resume the release branch from develop.

**Actions**:
1. Create or checkout `release/$RELEASE_VERSION` from `develop`
2. Validate the branch was created successfully

## Phase 4: Version File Updates

**Goal**: Update version across project files.

**Actions**:
1. Identify version files using patterns from the `gitflow-workflow` skill references (package.json, Cargo.toml, VERSION, etc.)
2. Update version to `$RELEASE_VERSION` in all identified files
3. Commit changes with message: `chore: bump version to $RELEASE_VERSION` and include `Co-Authored-By` footer
4. Push the branch to origin if newly created

**Note**: CHANGELOG.md is NOT updated during start-release. The `## [Unreleased]` section will be processed during finish-release when commits are analyzed and changelog entries are generated.
