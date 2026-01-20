---
name: conventional-commits
description: This skill should be used when the user asks to "create a commit", "follow conventional commits", "analyze commit history", "check commit format", or mentions "Conventional Commits specification". Provides expertise in creating conventional commits following the Commitizen (cz) style and v1.0.0 specification.
version: 0.2.0
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/validate-commit-pretool.sh"
          timeout: 5
---

## Core Rules

**Format**:
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Title Requirements**:
- ALL LOWERCASE (no capitalization in description)
- <50 characters
- Imperative mood (e.g., "add" not "added")
- No period at end
- Add "!" before ":" for breaking changes (e.g., `feat!:`, `feat(api)!:`)

**Common Types**: `feat:`, `fix:`, `docs:`, `refactor:`, `perf:`, `test:`, `chore:`, `build:`, `ci:`, `style:`

**Body** (optional): Blank line after title, ≤72 chars/line
- Bullet points listing what changed (start with verb: Add, Remove, Update, Fix)
- Paragraph explaining why

**Footer** (optional): Blank line after body
- Issue references: `Closes #123`, `Fixes #456`
- Breaking changes: `BREAKING CHANGE: <description>`

## Reference Files

Load only when needed:
- `references/basic-examples.md` - Common scenarios
- `references/types-reference.md` - All types and footer tokens
- `references/breaking-changes.md` - Breaking change examples
- `references/advanced-examples.md` - Complex scenarios
