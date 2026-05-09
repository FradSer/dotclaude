---
name: commit
description: Creates a conventional git commit using git-agent. This skill should be used when the user requests "commit", "git commit", "create commit", or wants to commit staged and unstaged changes following the conventional commits format. CRITICAL contract — the calling AI MUST auto-fill the argument with its own co-author string in the form `<model> <noreply@anthropic.com>` (e.g., `Claude Opus 4.7 <noreply@anthropic.com>`) using its own runtime model identity at invocation time. The skill executor runs as `model: haiku` and CANNOT self-derive (it would mis-attribute as haiku); if the argument is empty, the skill aborts and asks the calling AI to retry.
user-invocable: true
model: haiku
argument-hint: <co-author>
allowed-tools: ["Bash(git-agent:*)", "Bash(git:*)"]
---

CRITICAL:
- Do NOT run `git status`, `git diff`, `git log`, or any other commands before `git-agent commit`.
- The calling AI (the parent Claude in the user's session) MUST auto-fill `$ARGUMENTS` with its OWN co-author string `<model> <noreply@anthropic.com>` (e.g., `Claude Opus 4.7 <noreply@anthropic.com>`) **before** invoking this skill — `argument-hint: <co-author>` documents this. The skill always passes `$ARGUMENTS` through verbatim as `--co-author "$ARGUMENTS"`.
- The executor runs as `model: haiku` and is NOT the calling AI. It MUST NOT self-derive co-author from its own identity — that would mis-attribute every commit as haiku regardless of who actually did the work.

1. Derive a one-sentence intent from the conversation.
2. Verify `$ARGUMENTS` is non-empty. If empty or whitespace, abort and emit: `Error: /git:commit requires the calling AI's co-author string (e.g., "Claude Opus 4.7 <noreply@anthropic.com>"). The skill executor cannot self-derive without mis-attributing. Parent AI: re-invoke with your own model identity as the argument.` Do NOT run `git-agent commit` in this case.
3. Run: `git-agent commit --intent "<intent>" --co-author "$ARGUMENTS"`
4. On auth error (401), retry the same command with `--free` appended; keep the `--co-author` flag.
5. Fallback (binary unavailable): manual `git commit` with Conventional Commits format via HEREDOC, including a `Co-Authored-By: $ARGUMENTS` trailer in the message body.

CLI reference: `${CLAUDE_PLUGIN_ROOT}/references/cli.md`
