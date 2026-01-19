---
allowed-tools: Bash(git:*), Read, Write, Glob, AskUserQuestion
description: Create atomic conventional git commit
model: haiku
---

## Your Task

1. **Check for configuration**: Check if `.claude/git.local.md` exists. If not, load the `git-config` skill using the `Skill` tool and follow its workflow to analyze the project and generate configuration interactively.
2. **Load the `conventional-commits` skill** using the `Skill` tool to access conventional commit capabilities.
3. **Perform safety checks** on pending changes:
   - **Detect sensitive files**: Check for files that may contain secrets (`.env`, `.env.*`, `*credentials*`, `*secrets*`, `*password*`, `*.key`, `*.pem`, `config/database.yml`, etc.)
   - **Warn about large files**: Identify files >1MB that may be unintentional (binary files, logs, etc.)
   - **Check commit size**: If total changes exceed 500 lines, suggest breaking into smaller atomic commits
   - If issues detected, warn user and ask for confirmation before proceeding
4. Analyze pending changes to identify coherent logical units of work.
5. For each logical unit, stage the relevant files and create a conventional commit.
6. Repeat until every change is committed.
