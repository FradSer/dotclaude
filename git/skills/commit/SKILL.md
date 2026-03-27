---
name: commit
description: Creates a conventional git commit using git-agent. This skill should be used when the user requests "commit", "git commit", "create commit", or wants to commit staged and unstaged changes following the conventional commits format. When invoking, pass the calling Claude model name as argument (e.g., "Claude Opus 4.6").
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

CLI reference: `${CLAUDE_PLUGIN_ROOT}/references/cli.md`
