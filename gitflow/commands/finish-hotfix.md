---
allowed-tools: Bash(git:*), Read, Write, Skill
description: Complete and merge hotfix branch
model: haiku
argument-hint: [version]
---

## Your Task

1. **Load the `gitflow-workflow` skill** using the `Skill` tool to access GitFlow workflow capabilities.
2. Gather context: current branch, git status, recent commits, version files.
3. Validate branch follows `hotfix/*` convention and working tree is clean.
4. Run tests if available and resolve any failures.
5. Merge to main and develop, create version tag, push all changes.
6. Delete hotfix branch locally and remotely.
