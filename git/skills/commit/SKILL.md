---
name: commit
description: This skill should be used when the user requests "commit", "git commit", "create commit", or wants to commit staged/unstaged changes following conventional commits format
user-invocable: true
allowed-tools: ["Bash(git:*)", "Read", "Write", "Edit", "Glob", "AskUserQuestion", "Skill", "Task"]
model: haiku
---

## Background Knowledge

### Commit Format Rules

**Structure**:
```
<type>(<scope>): <description>

[optional context paragraph]

- <Action> <component> <detail>

[explanation paragraph - REQUIRED, explains the "why" behind changes]

Co-Authored-By: <Model Name> <noreply@anthropic.com>
```

**Rules**:
- **Title**: ALL LOWERCASE, <50 chars, imperative, no period. Add "!" before ":" for breaking changes
- **Types**: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `chore`, `build`, `ci`, `style`
- **Body** (REQUIRED): Bullet points with `- ` prefix, imperative verbs, ≤72 chars/line
- **Explanation paragraph** (REQUIRED): Explains the "why" behind the changes, not just the "what"
- **Footer**: `Co-Authored-By` is REQUIRED for all AI commits

## Workflow Execution

**Launch a general-purpose agent** that executes all 4 phases in a single task. This ensures atomic execution and proper context preservation.

**Prompt template**:
```
Execute the complete commit workflow (4 phases) for any staged/unstaged changes.

## Phase 1: Configuration Verification
1. Read `.claude/git.local.md` to load project configuration
2. If file not found, **load `git:config-git` skill** using the Skill tool to create it
3. Extract valid scopes from YAML frontmatter

## Phase 2: Change Analysis
1. Run `git diff --cached` and `git diff` to get code differences
2. Analyze diff to identify logical units
3. Infer scope(s) from file paths and changes using the valid scopes loaded in Phase 1
4. If inferred scope not in the valid scopes list, **load `git:config-git` skill** using the Skill tool to update configuration

## Phase 3: AI Code Quality Check (model: sonnet)
1. Review changes for AI slop patterns
2. Remove all AI generated slop introduced in the git diff:
   - Extra comments that a human wouldn't add or is inconsistent with the rest of the file
   - Extra defensive checks or try/catch blocks that are abnormal for that area of the codebase (especially if called by trusted/validated codepaths)
   - Casts to `any` to get around type issues
   - Any other style that is inconsistent with the file

## Phase 4: Commit Creation
1. Draft commit message following Conventional Commits format:
   - Title: lowercase, <50 chars, imperative, no period
   - Context paragraph: optional background before bullet points
   - Bullet points with `- ` prefix, imperative verbs, ≤72 chars/line
   - Explanation paragraph after bullet points (REQUIRED) - explains the "why"
   - Footer: Co-Authored-By: <Model Name> <noreply@anthropic.com>
2. Validate message format
3. Stage files and create commit

If no changes, report "No changes to commit" and exit.
```

**Execute**: Launch a general-purpose agent using the prompt template above
