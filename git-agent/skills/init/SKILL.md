---
name: init
description: Initializes or optimizes git-agent configuration, regenerates commit scopes from git history, and re-derives .gitignore rules. Use when setting up git-agent in a repo, when commit scopes drift from the current directories, or when asked to "init git-agent", "regenerate scopes", or "update gitignore".
user-invocable: true
argument-hint: "[--scope | --gitignore]"
allowed-tools: ["Bash(git-agent:*)"]
---

## Execution

Execute initialization or optimization based on `$ARGUMENTS`:

1. **Optimize commit scopes** (regenerate from history):
   ```bash
   git-agent init --scope --force
   ```
2. **Re-derive `.gitignore`** (preserve custom rules):
   ```bash
   git-agent init --gitignore
   ```
3. **Full initialization** (both scopes and `.gitignore`):
   ```bash
   git-agent init --scope --gitignore
   ```

Report the updated configuration status upon completion.

CLI Reference: `../../references/cli.md`
