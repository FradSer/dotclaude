---
name: start-release
allowed-tools: Bash(git:*), Read, Write, Skill
description: Start new release branch
model: haiku
argument-hint: [version]
user-invocable: true
---

## Your Task

1. **Load the `gitflow:gitflow-workflow` skill** using the `Skill` tool to access GitFlow workflow capabilities.
2. Gather context: current branch, existing release branches, latest tag, commit history.
3. Normalize the provided version from `$ARGUMENTS` to `$RELEASE_VERSION` using the normalization procedure defined in the `gitflow-workflow` skill references (accept v1.2.3 or 1.2.3, normalize to 1.2.3).
4. Decide version (use `$RELEASE_VERSION` if provided, otherwise calculate semantic version from conventional commits using the rules in `gitflow-workflow` skill references).
5. Create or resume `release/$RELEASE_VERSION` from `develop`.
6. Update version files:
   - Identify version files using patterns from the `gitflow-workflow` skill references (package.json, Cargo.toml, VERSION, etc.).
   - Update version to `$RELEASE_VERSION`.
   - Commit changes: `chore: bump version to $RELEASE_VERSION` with `Co-Authored-By` footer.
   - **Optional:** Create `CHANGELOG.md` template if repo maintains changelogs (see `${CLAUDE_PLUGIN_ROOT}/examples/changelog.md`). Leave `## [Unreleased]` section for manual curation or automated generation during finish-release.
7. Push the branch to origin if newly created.
