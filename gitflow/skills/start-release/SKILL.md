---
name: start-release
allowed-tools: Bash(git:*), Read, Write, Skill
description: Start new release branch
model: haiku
argument-hint: [version]
user-invocable: true
---

## Your Task

1. **Load the `gitflow-workflow` skill** using the `Skill` tool to access GitFlow workflow capabilities.
2. Gather context: current branch, existing release branches, latest tag, commit history.
3. Normalize the provided version from `$ARGUMENTS` to `$RELEASE_VERSION` using the normalization procedure in `./references/naming-rules.md`.
4. Decide version (use `$RELEASE_VERSION` if provided, otherwise calculate semantic version from conventional commits).
5. Create or resume `release/$RELEASE_VERSION` from `develop`.
6. Update version files and changelog if the repo uses them.
7. Push the branch to origin if newly created.
