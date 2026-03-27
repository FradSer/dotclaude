---
name: config-git
description: Configures git setup for user identity and project conventions. This skill should be used when the user asks to "configure git", "setup git", "set commit scopes", or needs project-specific Git settings.
user-invocable: true
model: haiku
---

Spawn the `git:git` agent with subagent_type `git:git` and prompt: "Execute the **Configure** workflow."
