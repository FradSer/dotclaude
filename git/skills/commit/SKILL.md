---
name: commit
description: Creates a conventional git commit using git-agent. This skill should be used when the user requests "commit", "git commit", "create commit", or wants to commit staged and unstaged changes following the conventional commits format.
user-invocable: true
---

Identify the exact Claude model name powering this session. Valid values: `Claude Sonnet 4.6`, `Claude Opus 4.6`, `Claude Haiku 4.5` — use only these exact strings, no dates or model IDs.

Spawn the `git:git` agent with subagent_type `git:git` and prompt: "Execute the **Commit** workflow. Calling model: <exact model name>."
