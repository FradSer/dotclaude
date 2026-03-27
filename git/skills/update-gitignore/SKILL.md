---
name: update-gitignore
description: Creates or updates a .gitignore file using git-agent AI generation. This skill should be used when the user asks to "update gitignore", "create gitignore", "add ignore rules", or needs to initialize ignore rules for a project.
user-invocable: true
argument-hint: [additional-technologies]
model: haiku
---

Spawn the `git:git` agent with subagent_type `git:git` and prompt: "Execute the **Update .gitignore** workflow."
