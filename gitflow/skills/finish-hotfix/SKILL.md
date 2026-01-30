---
name: finish-hotfix
allowed-tools: Bash(git:*), Read, Write, Skill
description: Complete and merge hotfix branch
model: haiku
argument-hint: [version]
user-invocable: true
---

## Initialization

Load the `gitflow:gitflow-workflow` skill using the Skill tool to access GitFlow workflow capabilities.

## Phase 1: Context Validation

**Goal**: Gather and validate current hotfix branch state before merging.

**Actions**:
1. Run `git status` to check working tree status
2. Run `git log --oneline -10` to review recent commits
3. Identify version files in the repository
4. Validate current branch follows `hotfix/*` convention and working tree is clean

## Phase 2: Testing

**Goal**: Run automated tests to ensure hotfix quality before merge.

**Actions**:
1. Identify test commands available in the repository (check for test scripts in package.json, Makefile, etc.)
2. Run tests if available
3. If tests fail, report the failures and exit without merging; the user must fix issues first

## Phase 3: Version and Changelog Update

**Goal**: Normalize version and update CHANGELOG with hotfix details.

**Actions**:
1. Normalize the provided version from `$ARGUMENTS` to `$HOTFIX_VERSION` (accept `v1.2.3` or `1.2.3`, normalize to `1.2.3`)
2. Identify previous version tag using `git tag --sort=-v:refname`
3. Collect commits since previous tag following the user-facing principle defined in the `gitflow-workflow` skill (include feat, fix, refactor, docs, perf, deprecate, remove, security; exclude chore, build, ci, test, merge commits)
4. Update `CHANGELOG.md` (or create if missing) with the new version and date, following the format in `${CLAUDE_PLUGIN_ROOT}/examples/changelog.md`
5. Commit the updated `CHANGELOG.md` to the current hotfix branch using conventional commit format (e.g., `chore: update changelog for v$HOTFIX_VERSION`) and MUST include the `Co-Authored-By` footer

## Phase 4: Branch Merge and Tagging

**Goal**: Merge hotfix to production and create version tag.

**Actions**:
1. Identify the production branch (often `main` or `production`)
2. Merge the hotfix branch into the production branch (often with `--no-ff`)
3. Create version tag `v$HOTFIX_VERSION` on the production branch
4. Push the production branch and tags

## Phase 5: Propagation and Cleanup

**Goal**: Propagate hotfix changes to integration branch and clean up.

**Actions**:
1. Identify the integration branch (often `develop` or `main`)
2. Merge the production branch into the integration branch to propagate hotfix changes
3. Push the integration branch
4. Delete the hotfix branch locally and remotely (skip deletion if the branch is shared or the user requests to keep it)
