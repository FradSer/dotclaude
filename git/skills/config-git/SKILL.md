---
name: config-git
description: Configures git setup for user identity and project conventions. This skill should be used when the user asks to "configure git", "setup git", "set commit scopes", or needs project-specific Git settings.
user-invocable: true
model: haiku
allowed-tools: ["Bash(git-agent:*)", "Bash(git:*)", "Bash(ls:*)", "Bash(find:*)", "Read", "Write", "AskUserQuestion"]
---

1. Verify `git config user.name` and `user.email`; prompt if missing
2. `git-agent init --scope --force`
3. Read scopes from `.git-agent/config.yml`, validate naming:
   - Single words: use as-is
   - Multi-word: abbreviate to first letters (e.g., `multi-word` -> `mw`)
4. Create `.claude/git.local.md` from `${CLAUDE_PLUGIN_ROOT}/examples/git.local.md` with validated scopes

CLI reference: `${CLAUDE_PLUGIN_ROOT}/references/cli.md`
