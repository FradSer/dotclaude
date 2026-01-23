---
name: commit
description: Create atomic conventional git commit following the Commitizen (cz) style and v1.0.0 specification
user-invocable: true
allowed-tools: ["Bash(git:*)", "Read", "Write", "Glob", "AskUserQuestion", "Skill"]
model: haiku
version: 0.1.0
---

## Conventional Commits Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Title Rules

- ALL LOWERCASE (no capitalization in description)
- <50 characters
- Imperative mood (e.g., "add" not "added")
- No period at end
- Add "!" before ":" for breaking changes (e.g., `feat!:`, `feat(api)!:`)

**Common Types**: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `chore`, `build`, `ci`, `style`

## Body Rules (Mandatory)

- **Body is required** - all commits must include bullet points
- Blank line after title
- ≤72 chars/line
- **Bullet points**: use `- ` prefix, start with imperative verb (Add, Remove, Update, Fix)
- **Optional paragraphs**: context before bullets, explanation after bullets

**Valid formats**:
```
# Simple
- Add feature X
- Update component Y

# With explanation
- Add feature X
- Update component Y

This improves performance by 50%.

# With context
Previous implementation caused memory leaks.

- Refactor memory management
- Add cleanup handlers

Resolves memory issues in production.
```

## Footer (Optional)

Blank line after body, then optionally add footers:

- Issue references: `Closes #123`, `Fixes #456`
- Breaking changes: `BREAKING CHANGE: <description>`
- Co-authorship attribution: `Co-Authored-By: Name <email>`

**Example commit message:**
```
feat(auth): add oauth login flow

- Add Google OAuth 2.0 integration
- Implement callback endpoint handler
- Update session management

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

## Your Task

1. **Verify configuration exists**: Check if `.claude/git.local.md` exists. If NOT found, invoke `/config-git` to set up project-specific settings.

2. **Perform safety checks** on pending changes:
   - Detect sensitive files (credentials, secrets, .env files)
   - Warn about large files (>1MB) and large commits (>500 lines)
   - Request user confirmation if issues found

3. **Analyze pending changes** to identify coherent logical units of work and infer the needed commit scope(s). If any inferred scope is not listed in `.claude/git.local.md`, invoke `/config-git` to update the configuration before proceeding.

4. **For each logical unit**:
   a. Draft the commit message following the Conventional Commits format above
   b. **Validate the message** against the Title Rules and Body Rules:
      - Title: ALL LOWERCASE, <50 characters, imperative mood, no period at end
      - Body: Required; must include at least one `- ` bullet (imperative verb). May include context before bullets and summary/explanation after bullets. Blank line after title; ≤72 chars/line
      - Footer: MUST include Co-Authored-By with the current model
   c. Stage the relevant files
   d. Create the commit with the validated message (including Co-Authored-By footer)

5. **Repeat** until every change is committed.
