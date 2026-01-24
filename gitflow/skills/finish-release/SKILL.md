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
6. Merge into `main` (often with `--no-ff`), create the version tag.
7. Merge `main` back to `develop`, push all changes.
8. Delete release branch locally and remotely when appropriate.
9. Review changes and create GitHub release:
   - Get previous version tag: `git tag --list --sort=-creatordate | head -2 | tail -1`
   - Review changes: `git log <previous_tag>..v$RELEASE_VERSION --oneline --no-merges`
   - Create GitHub release: `gh release create v$RELEASE_VERSION --title "Release v$RELEASE_VERSION" --notes "<release notes>"`
   - If release already exists, update it: `gh release edit v$RELEASE_VERSION --notes "<updated notes>"`
