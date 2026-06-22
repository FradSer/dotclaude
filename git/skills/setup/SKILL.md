---
name: setup
description: Initializes git-agent for a repository — generates commit scopes from git history and .gitignore via AI. Use when the user asks to "configure git", "setup git", "set commit scopes", "update gitignore", "create gitignore", or needs project-specific Git settings.
user-invocable: true
argument-hint: "[scope|gitignore]"
model: haiku
allowed-tools: ["Bash(git-agent:*)", "Bash(git:*)", "Bash(ls:*)", "Bash(find:*)", "Read", "Write", "Edit", "AskUserQuestion"]
---

CRITICAL:
- Always preserve custom `.gitignore` rules before running `git-agent init --gitignore`.
- On auth error (401), retry the same `git-agent init` command with `--free` appended.

1. Verify `git config user.name` and `git config user.email`; if either is missing, use `AskUserQuestion` tool to collect it from the user.
2. Parse `$ARGUMENTS` to determine mode:
   - Empty → run both scope and gitignore
   - `scope` → run only scope generation
   - `gitignore` → run only .gitignore generation
3. If running gitignore and `.gitignore` already exists:
   - Read the current file
   - Identify lines that are NOT part of the standard git-agent generated block (anything between `# --- git-agent ---` markers or common auto-generated patterns)
   - Save those custom rules
4. Run `git-agent init` with the appropriate flags:
   - Both: `git-agent init --scope --gitignore --force`
   - Scope only: `git-agent init --scope --force`
   - Gitignore only: `git-agent init --gitignore --force`
5. On auth error (401), retry the same command with `--free` appended.
6. If custom `.gitignore` rules were saved in step 3, append them back and show `git diff .gitignore`.

CLI reference: `${CLAUDE_PLUGIN_ROOT}/references/cli.md`
