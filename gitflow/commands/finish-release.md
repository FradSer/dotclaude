---
allowed-tools: Bash(git:*), Read, Write, Skill
description: Complete and merge release branch
model: haiku
---

## Your Task

1. **Load the `gitflow-workflow` skill** using the `Skill` tool to access GitFlow workflow capabilities.
2. Gather context: current branch, git status, recent commits, version files.
3. Validate branch follows `release/*` convention and working tree is clean.
4. Run tests if available and resolve any failures.
5. Merge to main with `--no-ff`, create version tag.
6. Merge main back to develop, push all changes.
7. Delete release branch locally and remotely.
