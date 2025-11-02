---
description: Create or update .gitignore file
trigger: /gitignore
---

## Context

- Project guidelines: @CLAUDE.md
- Operating system: `uname -s`
- Existing .gitignore status: `test -f .gitignore && echo ".gitignore found" || echo ".gitignore not found"`
- Project files: Analyze repository structure to detect technologies
- Available templates: `curl -sL https://www.toptal.com/developers/gitignore/api/list`

## Requirements

- Combine detected platforms and `<additional-technologies (user may provide additional)>` into the generator request (e.g. `macos,node,docker`).
- Preserve existing custom sections when updating `.gitignore`.
- Present the resulting diff for confirmation.

## Your Task

1. Detect operating systems and technologies from context plus `<additional-technologies (user may provide additional)>`.
2. Generate or update `.gitignore` using the Toptal API while retaining custom rules.
3. Show the repository changes to confirm the update.

### Usage Examples

- `/gitignore` — Auto-detect and create `.gitignore`.
- `/gitignore react typescript` — Add React and TypeScript to detected technologies.

**Note:** The user may provide additional input after the command. Use that input as <additional-technologies> in the instructions above.
