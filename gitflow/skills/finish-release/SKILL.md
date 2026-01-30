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

## Phase 3: Changelog Generation

**Goal**: Generate changelog from commits and merge with manual entries.

**Actions**:
1. Normalize the provided version from `$ARGUMENTS` to `$RELEASE_VERSION` (accept `v1.2.3`, `1.2.3`, or `release/1.2.3`, normalize to `1.2.3`)
2. Identify previous version tag using `git tag --sort=-v:refname`
3. Collect commits since previous tag using `git log --oneline --no-merges <previous-tag>..HEAD`
4. Parse conventional commits and categorize by type following the mapping rules in `gitflow-workflow` skill references (see `references/changelog-generation.md` for detailed rules):
   - `feat:` → **Added**
   - `fix:` → **Fixed**
   - `perf:` → **Changed** (with performance note)
   - `refactor:` → **Changed**
   - `docs:` → **Changed** (documentation-specific)
   - `BREAKING CHANGE:` or `!` → **Changed** (mark as BREAKING)
   - Security-related keywords → **Security**
   - Deprecation keywords → **Deprecated**
   - Removal keywords → **Removed**
   - Exclude: `chore:`, `build:`, `ci:`, `test:`, merge commits
5. Extract any existing `## [Unreleased]` entries from CHANGELOG.md for manual curation
6. Generate new version section following Keep a Changelog format from `${CLAUDE_PLUGIN_ROOT}/examples/changelog.md`
7. Merge manual entries from `[Unreleased]` with generated entries (prioritize manual curation, deduplicate)
8. Update CHANGELOG.md: replace `## [Unreleased]` section with the new version section, keeping an empty `## [Unreleased]` at the top
9. Commit the updated `CHANGELOG.md` to the current release branch: `chore: update changelog for v$RELEASE_VERSION` with `Co-Authored-By` footer

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
