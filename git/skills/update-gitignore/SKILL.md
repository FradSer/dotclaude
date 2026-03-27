---
name: update-gitignore
description: Creates or updates a .gitignore file using git-agent AI generation. This skill should be used when the user asks to "update gitignore", "create gitignore", "add ignore rules", or needs to initialize ignore rules for a project.
user-invocable: true
argument-hint: [additional-technologies]
model: haiku
allowed-tools: ["Bash(git-agent:*)", "Bash(git:*)", "Read", "Write", "Edit"]
---

1. Preserve custom rules from existing .gitignore
2. `git-agent init --gitignore --force`
3. On auth error (401), retry with `--free`
4. Re-add preserved custom rules
5. Show diff

CLI reference: `${CLAUDE_PLUGIN_ROOT}/references/cli.md`
