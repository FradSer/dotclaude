---
name: conventional-commits
description: This skill should be used when creating conventional commits, following the Conventional Commits specification (v1.0.0), analyzing commit history for conventional format, or managing commit message conventions.
version: 0.2.0
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

## Workflow

1. **Analyze changes**: Identify atomic logical units of work
2. **Determine type**: `feat:` (new feature), `fix:` (bug fix), or other (see `references/types-reference.md` if needed)
3. **Add scope** (optional): Lowercase, 1-2 words for codebase area
4. **Write title**: `<type>[scope]: <description>` - all lowercase, <50 chars
5. **Write body** (if needed): Bullets for what changed, paragraph for why
6. **Add footer** (if needed): Issue references or `BREAKING CHANGE:`
7. **Stage and commit**: Only files for this logical unit

For multiple unrelated changes, create separate commits for each logical unit.

## Reference Files

Load only when needed:
- `references/basic-examples.md` - Common scenarios
- `references/types-reference.md` - All types and footer tokens
- `references/breaking-changes.md` - Breaking change examples
- `references/advanced-examples.md` - Complex scenarios
