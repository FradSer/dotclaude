---
allowed-tools: Bash(git:*), Read, Write, Glob, AskUserQuestion
description: Create atomic conventional git commit
model: haiku
---

## Your Task

1. **Check for configuration**: Check if `.claude/git.local.md` exists. If not, load the `git-config` skill using the `Skill` tool and follow its workflow to analyze the project and generate configuration interactively.
2. **Load the `conventional-commits` skill** using the `Skill` tool to access conventional commit capabilities.
3. Analyze pending changes to identify coherent logical units of work.
4. For each logical unit, stage the relevant files and create a conventional commit.
5. Repeat until every change is committed.
