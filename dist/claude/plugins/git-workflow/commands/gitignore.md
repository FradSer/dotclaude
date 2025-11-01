---
allowed-tools: Task, Bash(curl:*), Bash(uname:*), Bash(git:*), Read, Write, Edit, Glob
description: Create or update .gitignore file
model: claude-haiku-4-5-20251001
argument-hint: [additional-technologies]
---

## Context

- Project guidelines: @CLAUDE.md
- Operating system: !`uname -s`
- Existing .gitignore: !`test -f .gitignore && echo ".gitignore found" || echo ".gitignore not found"`
- Project files: Analyze project structure to detect technologies
- Available templates: !`curl -sL https://www.toptal.com/developers/gitignore/api/list`

## Your task

**IMPORTANT: You MUST use the Task tool to complete ALL tasks.**

Create or update the .gitignore file for this project:

1. **Auto-detect technologies** from the context above and any additional technologies from: $ARGUMENTS

2. **Fetch and generate .gitignore:**
   - Combine detected OS and technologies (e.g., "macos,node,docker")
   - Add any additional technologies from arguments: $ARGUMENTS
   - Generate .gitignore: `curl -sL https://www.toptal.com/developers/gitignore/api/{params}`
   - Preserve existing custom rules when updating

3. **Verify results** by showing repository changes

**Usage examples:**
- `/gitignore` - Auto-detect and create .gitignore
- `/gitignore react typescript` - Add React and TypeScript to detected technologies
