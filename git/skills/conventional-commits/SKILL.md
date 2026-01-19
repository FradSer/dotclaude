---
name: conventional-commits
description: This skill should be used when creating conventional commits, following the Conventional Commits specification (v1.0.0), analyzing commit history for conventional format, or managing commit message conventions.
version: 0.1.0
---

## Overview

This skill provides expertise in creating and managing conventional commits following the [Conventional Commits specification](https://www.conventionalcommits.org/en/v1.0.0/). It ensures commits follow the specification with proper formatting, types, scopes, and message structure.

## Specification Summary

The Conventional Commits specification provides a lightweight convention for commit messages:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Commit Types

1. **`fix:`** - Patches a bug (correlates with PATCH in SemVer)
2. **`feat:`** - Introduces a new feature (correlates with MINOR in SemVer)
3. **BREAKING CHANGE** - Introduces a breaking API change (correlates with MAJOR in SemVer)
4. **Other types** - `build:`, `chore:`, `ci:`, `docs:`, `style:`, `refactor:`, `perf:`, `test:`, etc.

### Message Structure

- **Type**: Required noun (feat, fix, etc.) followed by optional scope, optional "!", and required colon and space
- **Description**: Short summary immediately after the colon and space
- **Body**: Optional, begins one blank line after description, explains "why" not "how"
- **Footer**: Optional, one blank line after body, uses git trailer format (e.g., `Closes #123`, `BREAKING CHANGE: description`)

### Breaking Changes

Breaking changes MUST be indicated either:
- In the type/scope prefix with "!" immediately before ":" (e.g., `feat!:`, `feat(api)!:`)
- As a footer entry: `BREAKING CHANGE: <description>`

## Capabilities

- Creates conventional commits following the specification v1.0.0
- Identifies atomic logical units of work from code changes
- Properly indicates breaking changes with "!" or `BREAKING CHANGE:` footer
- Validates commit message format against the specification

## Workflows

### Creating Conventional Commits

**Step 1: Analyze Changes**
1. Review pending changes (staged and unstaged)
2. Identify logical units of work
3. Group related files that form a complete change

**Step 2: Determine Type and Scope**
1. Select the appropriate type: `feat:` (new features), `fix:` (bug fixes), or other types (see `references/types-reference.md`)
2. Select scope based on the codebase area affected (optional, lowercase, 1-2 words)
3. Add "!" before ":" if the change is breaking

**Step 3: Craft Commit Message**
1. **Title**: Format `<type>[optional scope]: <description>`, **ALL LOWERCASE**, <50 chars, imperative mood (no capitalization, no period at end)
2. **Body** (optional): Blank line after title, ≤72 chars/line
   - Start with bullet points listing **what changes were made** (specific, actionable items)
   - Each bullet starts with a verb (Add, Remove, Update, Fix, etc.)
   - Follow with a paragraph explaining **why** this change was needed (the motivation/context)
3. **Footer** (optional): Blank line after body, issue references (`Closes #123`, `Fixes #456`), or `BREAKING CHANGE:` if not using "!" in title

**Step 4: Create Commit**
1. Stage only files for this logical unit
2. Create commit with the crafted message
3. Verify commit message format

### Handling Multiple Logical Changes

When multiple unrelated changes exist:
1. Identify each discrete logical unit
2. Create separate commits for each unit
3. Ensure each commit is independently meaningful
4. Order commits logically (dependencies first)

### Breaking Changes

Breaking changes can be indicated with "!" in the title or `BREAKING CHANGE:` in the footer. See `references/breaking-changes.md` for examples.

### Validating Commit Messages

Validate against: format spec, type validity, message structure, breaking change indicators.

## Best Practices

- Each commit represents one complete, logical change (atomic)
- **Title MUST be all lowercase** - no capitalization except for type prefixes
- **Body structure**: List specific changes as bullets first, then explain why
- Each bullet point starts with a verb (Add, Remove, Update, Fix, Improve, etc.)
- Focus on "what changed" in bullets, "why it matters" in paragraph
- Use consistent scopes across the project
- Always indicate breaking changes clearly
- Use imperative mood in description (e.g., "add" not "added")
- No period at the end of title

## Examples

Available example files (load only when needed):
- `references/basic-examples.md` - Common commit scenarios (feat, fix, docs, refactor)
- `references/breaking-changes.md` - Breaking change examples
- `references/advanced-examples.md` - Complex scenarios (revert, multiple footers, etc.)
- `references/types-reference.md` - Complete type and footer token reference

## Additional Resources

- [Conventional Commits Specification](https://www.conventionalcommits.org/en/v1.0.0/)
- [Semantic Versioning](https://semver.org/)
