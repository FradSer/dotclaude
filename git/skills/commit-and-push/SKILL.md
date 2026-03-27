---
name: commit-and-push
description: Creates conventional git commits using git-agent and pushes to the remote repository. This skill should be used when the user asks to "commit and push", "push my changes", or wants to commit and immediately push to remote.
user-invocable: true
---

Identify the exact Claude model name powering this session. Valid values: `Claude Sonnet 4.6`, `Claude Opus 4.6`, `Claude Haiku 4.5` — use only these exact strings, no dates or model IDs.

Spawn the `git:git` agent with subagent_type `git:git` and prompt: "Execute the **Commit** workflow, then the **Push** workflow. Calling model: <exact model name>."
