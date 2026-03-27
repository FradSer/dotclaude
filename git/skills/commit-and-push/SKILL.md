---
name: commit-and-push
description: Creates conventional git commits using git-agent and pushes to the remote repository. This skill should be used when the user asks to "commit and push", "push my changes", or wants to commit and immediately push to remote. When invoking, pass the calling Claude model name as argument (e.g., "Claude Opus 4.6").
user-invocable: true
model: haiku
allowed-tools: ["Bash(git-agent:*)", "Bash(git:*)"]
---

Do NOT run `git status`, `git diff`, `git log`, or any other commands before `git-agent commit`.

1. Derive a one-sentence intent from the conversation
2. If `$ARGUMENTS` contains a Claude model name, use it as co-author: `git-agent commit --intent "<intent>" --co-author "<model> <noreply@anthropic.com>"`
3. Otherwise: `git-agent commit --intent "<intent>"`
4. On auth error (401), retry with `--free`
5. Fallback (binary unavailable): manual `git commit` with Conventional Commits format via HEREDOC
6. `git push` (add `-u origin <branch>` if upstream not set)

CLI reference: `${CLAUDE_PLUGIN_ROOT}/references/cli.md`
