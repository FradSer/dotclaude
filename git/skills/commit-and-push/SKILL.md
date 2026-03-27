---
name: commit-and-push
description: Creates conventional git commits using git-agent and pushes to the remote repository. This skill should be used when the user asks to "commit and push", "push my changes", or wants to commit and immediately push to remote.
user-invocable: true
model: haiku
allowed-tools: ["Bash(git-agent:*)", "Bash(git:*)"]
---

Do NOT run `git status`, `git diff`, `git log`, or any other commands before `git-agent commit`.

1. Derive a one-sentence intent from the conversation
2. `git-agent commit --intent "<intent>"`
3. On auth error (401), retry with `--free`
4. Fallback (binary unavailable): manual `git commit` with Conventional Commits format via HEREDOC
5. `git push` (add `-u origin <branch>` if upstream not set)

CLI reference: `${CLAUDE_PLUGIN_ROOT}/references/cli.md`
