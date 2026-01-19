---
allowed-tools: Bash(git:*), Read, Write, Skill
description: Start new release branch
model: haiku
argument-hint: [version]
---

## Your Task

1. **Load the `gitflow-workflow` skill** using the `Skill` tool to access GitFlow workflow capabilities.
2. Gather context: current branch, existing release branches, latest tag, commit history.
3. Calculate semantic version from conventional commits if not provided.
4. Create or resume `release/$ARGUMENTS` branch from develop.
5. Update version files and changelog.
6. Push the branch to origin if newly created.
