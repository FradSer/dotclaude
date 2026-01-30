---
name: finish-release
allowed-tools: Bash(git:*), Bash(gh:*), Read, Write, Skill
description: Complete and merge release branch
model: haiku
argument-hint: [version]
user-invocable: true
---

## Initialization

Load the `gitflow:gitflow-workflow` skill using the Skill tool to access GitFlow workflow capabilities.

## Phase 1: Context Validation

**Goal**: Gather and validate current release branch state before merging.

**Actions**:
1. Run `git status` to check working tree status
2. Run `git log --oneline -20` to review recent commits
3. Identify version files in the repository
4. Validate current branch follows `release/*` convention and working tree is clean

## Phase 2: Testing

**Goal**: Run automated tests to ensure release quality before merge.

**Actions**:
1. Identify test commands available in the repository (check for test scripts in package.json, Makefile, etc.)
2. Run tests if available
3. If tests fail, report the failures and exit without merging; the user must fix issues first

## Phase 3: Version and Changelog Update

**Goal**: Normalize version and update CHANGELOG with release details.

**Actions**:
1. Normalize the provided version from `$ARGUMENTS` to `$RELEASE_VERSION` (accept `v1.2.3`, `1.2.3`, or `release/1.2.3`, normalize to `1.2.3`)
2. Identify previous version tag using `git tag --sort=-v:refname`
3. Collect commits since previous tag following the user-facing principle defined in the `gitflow-workflow` skill (include feat, fix, refactor, docs, perf, deprecate, remove, security; exclude chore, build, ci, test, merge commits)
4. Update `CHANGELOG.md` (create if missing) with the new version and date, following the format in `${CLAUDE_PLUGIN_ROOT}/examples/changelog.md`
5. If `CHANGELOG.md` was manually updated during start-release, merge or reconcile entries while preserving manual curation
6. Commit the updated `CHANGELOG.md` to the current release branch using conventional commit format (e.g., `chore: update changelog for v$RELEASE_VERSION`) and MUST include the `Co-Authored-By` footer

## Phase 4: Branch Merge and Tagging

**Goal**: Merge release to main and create version tag.

**Actions**:
1. Merge the release branch into `main` (often with `--no-ff`)
2. Create version tag `v$RELEASE_VERSION` on main
3. Push main branch and tags

## Phase 5: Propagation

**Goal**: Propagate release changes back to develop branch.

**Actions**:
1. Merge `main` back to `develop` to propagate release changes
2. Push develop branch
3. Delete release branch locally and remotely (skip deletion if the branch is shared or the user requests to keep it)

## Phase 6: Release Publishing

**Goal**: Create GitHub release with changelog content.

**Actions**:
1. Extract changelog content for `v$RELEASE_VERSION` from `CHANGELOG.md`
2. Use the `gh` CLI to create the release: `gh release create v$RELEASE_VERSION --title "Release v$RELEASE_VERSION" --notes "<content from CHANGELOG for this version>"`
3. Verify the release was published successfully
