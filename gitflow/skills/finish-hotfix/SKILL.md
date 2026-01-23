---
name: finish-hotfix
allowed-tools: Bash(git:*), Read, Write, Skill
description: Complete and merge hotfix branch
model: haiku
argument-hint: [version]
user-invocable: true
---

## Your Task

1. **Load the `gitflow-workflow` skill** using the `Skill` tool to access GitFlow workflow capabilities.
2. Gather context: current branch, git status, recent commits, version files.
3. Validate branch follows `hotfix/*` convention and working tree is clean.
4. Run tests if available and resolve any failures.
5. Normalize the provided version from `$ARGUMENTS` to `$HOTFIX_VERSION`:
   - Accept `v1.2.3` or `1.2.3`
   - Normalize to `1.2.3` (and tag as `v$HOTFIX_VERSION` when tagging)
6. Merge into the production branch (often `main`/`production`), create the version tag, then propagate the changes to the integration branch (often `develop`/`main`), and push all changes.
7. Delete the hotfix branch locally and remotely when appropriate.
