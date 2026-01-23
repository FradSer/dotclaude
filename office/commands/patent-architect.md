---
title: Generate Patent Application
description: Generate Chinese patent application forms from technical ideas
argument-hint: "INVENTION_IDEA"
allowed-tools: Skill
---

## Your Task

This command is a user-friendly shortcut to the `patent-architect` skill.

1. **Load the `patent-architect` skill** using the `Skill` tool with `skill: "patent-architect"` and pass the invention idea as input via the `args` parameter.
2. **Follow the skill workflow** - The skill contains all procedures for understanding the invention, conducting prior art search, and generating the application form.
3. **Save Output** - The skill will save the final patent application to `docs/YYYY-MM-DD-ShortName.md`.

