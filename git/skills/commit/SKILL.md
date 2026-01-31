---
name: commit
description: This skill should be used when the user requests "commit", "git commit", "create commit", or wants to commit staged/unstaged changes following conventional commits format
user-invocable: true
allowed-tools: ["Bash(git:*)", "Read", "Write", "Edit", "Glob", "AskUserQuestion", "Skill", "Task"]
argument-hint: "[no arguments needed]"
model: haiku
version: 0.3.0
---

## Background Knowledge

### Commit Format Rules

**Structure**:
```
<type>(<scope>): <description>

[optional context paragraph]

- <Action> <component> <detail>

[explanation paragraph]

Co-Authored-By: <Model Name> <noreply@anthropic.com>
```

**Rules**:
- **Title**: ALL LOWERCASE, <50 chars, imperative, no period. Add "!" before ":" for breaking changes
- **Types**: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `chore`, `build`, `ci`, `style`
- **Body** (REQUIRED): Bullet points with `- ` prefix, imperative verbs, ≤72 chars/line
- **Footer**: `Co-Authored-By` is REQUIRED for all AI commits

## Phase 1: Configuration Verification

**Goal**: Load project-specific git configuration and valid scopes.

**Actions**:
1. **FIRST**: Read `.claude/git.local.md` to load project configuration
2. If file not found, **load `git:config-git` skill** using the Skill tool to create it
3. Extract valid scopes from `scopes:` list in YAML frontmatter

## Phase 2: Change Analysis

**Goal**: Identify logical units of work and infer commit scopes.

**Actions**:
1. Run `git diff --cached` and `git diff` to get code differences (MUST NOT traverse files directly)
2. Analyze diff to identify coherent logical units
3. Infer scope(s) from file paths and changes using the valid scopes loaded in Phase 1
4. If inferred scope not in the valid scopes list, **load `git:config-git` skill** using the Skill tool to update configuration

## Phase 3: AI Code Quality Check

**Goal**: Remove AI-generated slop before committing.

**Actions**:
1. Launch agent with Task tool (model: sonnet) to review changes
2. Remove AI patterns: extra comments, unnecessary defensive checks, `any` casts, inconsistent style
3. Agent runs autonomously without user confirmation

## Phase 4: Commit Creation

**Goal**: Create atomic commits following Conventional Commits format.

**Actions** (repeat for each logical unit):
1. Draft commit message per `Commit Format Rules` above
2. Validate: title <50 chars lowercase imperative; body has bullets + explanation paragraph; footer has `Co-Authored-By`
3. Stage relevant files and create commit
