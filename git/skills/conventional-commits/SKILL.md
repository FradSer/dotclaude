---
name: conventional-commits
description: This skill should be used when the user asks to "create a commit", "follow conventional commits", "analyze commit history", "check commit format", or mentions "Conventional Commits specification". Provides expertise in creating conventional commits following the Commitizen (cz) style and v1.0.0 specification.
version: 0.2.1
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

**Body** (optional but recommended): Blank line after title, ≤72 chars/line
- **Bullet list**: What changed (start with verb: Add, Remove, Update, Fix)
- **Blank line**
- **Explanation paragraph**: Why it matters, what impact it has

Example body structure:
```
- Add new user authentication endpoint
- Update middleware to validate JWT tokens
- Remove legacy session handling code

Modernizes the authentication system and improves security
by using industry-standard JWT tokens instead of sessions.
```

**IMPORTANT - Body Requirements** (enforced by git plugin hook):
- **Body is mandatory** - all commits must include a body with bullet points
- **Bullet points required** - use `- ` prefix for each change item
- **Imperative verbs** - start each bullet with a verb (Add, Remove, Update, Fix, Implement, etc.)
- **Optional paragraphs**:
  - Context paragraph before bullets (to explain background)
  - Explanation paragraph after bullets (to explain why/impact)

**Valid body formats**:
```
# Simple: Just bullet points
- Add feature X
- Update component Y

# With explanation:
- Add feature X
- Update component Y

This improves performance by 50%.

# With context and explanation:
Previous implementation caused memory leaks.

- Refactor memory management
- Add cleanup handlers

Resolves memory issues in production.
```

**Footer** (optional): Blank line after body
- Issue references: `Closes #123`, `Fixes #456`
- Breaking changes: `BREAKING CHANGE: <description>`

## Reference Files

Load only when needed:
- `references/basic-examples.md` - Common scenarios
- `references/types-reference.md` - All types and footer tokens
- `references/breaking-changes.md` - Breaking change examples
- `references/advanced-examples.md` - Complex scenarios
