---
name: finish-release
allowed-tools: Bash(git:*), Bash(gh:*), Read, Write, Skill
description: Complete and merge release branch
model: haiku
argument-hint: [version]
user-invocable: true
---

## Your Task

1. **Load the `gitflow:gitflow-workflow` skill** using the `Skill` tool to access GitFlow workflow capabilities.
2. Gather context: current branch, git status, recent commits, version files.
3. Validate branch follows `release/*` convention and working tree is clean.
4. Run tests if available and resolve any failures.
5. Normalize the provided version from `$ARGUMENTS` to `$RELEASE_VERSION`:
   - Accept `v1.2.3`, `1.2.3`, or `release/1.2.3`
   - Normalize to `1.2.3` (and tag as `v$RELEASE_VERSION` when tagging)
6. **Update CHANGELOG**:
   - Identify previous version tag.
   - Collect commits since previous tag (filtering for `feat`, `fix`, etc.).
   - See `${CLAUDE_PLUGIN_ROOT}/examples/changelog.md` for the standard changelog template format.
   - Update `CHANGELOG.md` (or create if missing) with the new version and date.
   - Commit the updated `CHANGELOG.md` to the current release branch using conventional commit format (e.g., `chore: update changelog for v$RELEASE_VERSION`).
   - **Commit Rules**: The message title MUST be lowercase, under 50 characters, use imperative mood, and MUST include the `Co-Authored-By` footer.
7. Merge into `main` (often with `--no-ff`), create the version tag.
8. Merge `main` back to `develop`, push all changes.
9. Delete release branch locally and remotely when appropriate.
10. **Publish GitHub Release**:
   - Use the `gh` CLI to create the release using the version tag.
   - `gh release create v$RELEASE_VERSION --title "Release v$RELEASE_VERSION" --notes "<content from CHANGELOG for this version>"`
