---
name: commit
description: Creates a conventional git commit using git-agent. This skill should be used when the user requests "commit", "git commit", "create commit", or wants to commit staged and unstaged changes following the conventional commits format.
user-invocable: true
model: haiku
---

Determine the current Claude model name (Sonnet 4.6, Opus 4.6, or Haiku 4.5) from the session context.

Spawn the `git:git` agent with subagent_type `git:git` and prompt: "Execute the **Commit** workflow. Calling model: Claude <Model> <Version>."
