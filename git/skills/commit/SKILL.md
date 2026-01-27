---
name: commit
description: Create atomic conventional git commit following the Commitizen (cz) style and v1.0.0 specification
user-invocable: true
allowed-tools: ["Bash(git:*)", "Read", "Write", "Glob", "AskUserQuestion", "Skill"]
argument-hint: "[no arguments needed]"
model: haiku
version: 0.1.0
---

## Conventional Commits Quick Reference

Format: `<type>[scope]: <description>` + mandatory bullet-point body + optional footers

**Title**: ALL LOWERCASE, <50 chars, imperative mood, no period. Add ! for breaking changes.

**Types**: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `chore`, `build`, `ci`, `style`

**Body** (REQUIRED): Blank line after title. MUST have bullet-point summary with imperative verbs. MUST have explanation paragraph after bullets. MAY include context before bullets. ≤72 chars/line.

**Footer** (Optional): `Closes #123`, `BREAKING CHANGE: ...`, `Co-Authored-By: ...`

**Example**:
```
<type>(<scope>): <description>

- <Action> <component> <detail>
- <Action> <component> <detail>

<Explanation paragraph describing why these changes were made>

Co-Authored-By: <Model Name> <noreply@anthropic.com>
```

See `references/format-rules.md` for complete specification and examples.

## Phase 1: Configuration Verification

**Goal**: Ensure project-specific git configuration exists and load valid scopes

**Actions**:
1. Check if `.claude/git.local.md` exists
2. If NOT found, invoke `/config-git` skill using the Skill tool to set up project-specific settings
3. If found, read the file and extract valid scopes from the YAML frontmatter `scopes:` section

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
1. Run `git diff --cached` (for staged changes) and `git diff` (for unstaged changes) to get the actual code differences - MUST NOT traverse files directly
2. Analyze the diff output to identify coherent logical units of work
3. Infer the needed commit scope(s) for each logical unit based on the file paths and code changes shown in the diff
4. If any inferred scope is not listed in `.claude/git.local.md`, invoke `/config-git` to update the configuration before proceeding

---

## Phase 4: Commit Creation

**Goal**: Create atomic commits following Conventional Commits format

**Actions**:

For each logical unit:

1. Draft the commit message following the Conventional Commits quick reference above (see `references/format-rules.md` for detailed rules)
2. **Validate the message** against format requirements:
   - Title: ALL LOWERCASE, <50 characters, imperative mood, no period at end
   - Body: Required; MUST include at least one `- ` bullet (imperative verb) as summary. MUST include explanation paragraph after bullets. MAY include context before bullets. Blank line after title; ≤72 chars/line
   - Footer: MUST include Co-Authored-By with the current model
3. Stage the relevant files
4. Create the commit with the validated message (including Co-Authored-By footer)
5. **Repeat** until every change is committed
