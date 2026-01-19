---
allowed-tools: Bash(git:*), Read, Write, Glob, AskUserQuestion
description: Create atomic conventional git commit and push to remote
model: haiku
---

## Your Task

1. **Check for configuration**: Check if `.claude/git.local.md` exists. If not, load the `git-config` skill using the `Skill` tool and follow its workflow to analyze the project and generate configuration interactively.
2. **Load the `conventional-commits` skill** using the `Skill` tool to access conventional commit capabilities.
3. Review pending changes to determine discrete logical units of work.
4. For each unit, stage the relevant files and create a conventional commit.
5. After committing all units, push the branch to the remote, configuring the upstream if it does not exist.
