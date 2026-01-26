---
name: commit
description: Create atomic conventional git commit following the Commitizen (cz) style and v1.0.0 specification
user-invocable: true
allowed-tools: ["Bash(git:*)", "Read", "Write", "Glob", "AskUserQuestion", "Skill"]
argument-hint: "[no arguments needed]"
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

## Phase 1: Configuration Verification

**Goal**: Ensure project-specific git configuration exists

**Actions**:
1. Check if `.claude/git.local.md` exists
2. If NOT found, invoke `/config-git` to set up project-specific settings

---

## Phase 2: Safety Validation

**Goal**: Perform safety checks on pending changes before committing

**Actions**:
1. Detect sensitive files (credentials, secrets, .env files)
2. Warn about large files (>1MB) and large commits (>500 lines)
3. Request user confirmation if issues found

---

## Phase 3: Change Analysis

**Goal**: Identify coherent logical units of work and infer commit scopes

**Actions**:
1. Run `git diff --cached` (for staged changes) and `git diff` (for unstaged changes) to get the actual code differences
2. Analyze the diff output to identify coherent logical units of work
3. Infer the needed commit scope(s) for each logical unit based on the file paths and code changes shown in the diff
4. If any inferred scope is not listed in `.claude/git.local.md`, invoke `/config-git` to update the configuration before proceeding

---

## Phase 4: Commit Creation

**Goal**: Create atomic commits following Conventional Commits format

**Actions**:

For each logical unit:

1. Draft the commit message following the Conventional Commits format above
2. **Validate the message** against the Title Rules and Body Rules:
   - Title: ALL LOWERCASE, <50 characters, imperative mood, no period at end
   - Body: Required; must include at least one `- ` bullet (imperative verb). May include context before bullets and summary/explanation after bullets. Blank line after title; ≤72 chars/line
   - Footer: MUST include Co-Authored-By with the current model
3. Stage the relevant files
4. Create the commit with the validated message (including Co-Authored-By footer)
5. **Repeat** until every change is committed
