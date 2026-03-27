---
name: commit-and-push
description: Creates conventional git commits using git-agent and pushes to the remote repository. This skill should be used when the user asks to "commit and push", "push my changes", or wants to commit and immediately push to remote.
user-invocable: true
model: haiku
---

Spawn the `git:git` agent with subagent_type `git:git` and prompt: "Execute the **Commit** workflow, then the **Push** workflow."
