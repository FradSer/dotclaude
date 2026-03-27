---
name: commit
description: Creates a conventional git commit using git-agent. This skill should be used when the user requests "commit", "git commit", "create commit", or wants to commit staged and unstaged changes following the conventional commits format.
user-invocable: true
allowed-tools: ["Bash(git-agent:*)", "Bash(git:*)", "Read", "Write", "Edit", "Glob", "AskUserQuestion", "Skill", "Task"]
model: haiku
---

## Workflow Execution

**Launch a general-purpose agent** that executes all 3 phases in a single task.

**Prompt template**:
```
Execute the complete commit workflow (3 phases) for any staged/unstaged changes.

## Phase 1: Configuration Verification
1. Read `.claude/git.local.md` to load project configuration
2. If file not found, **load `git:config-git` skill** using the Skill tool to create it
3. Extract valid scopes from YAML frontmatter

## Phase 2: AI Code Quality Check (model: sonnet)
1. Run `git diff --cached` and `git diff` to review changes for AI slop patterns
2. Remove all AI generated slop introduced in the git diff:
   - Extra comments that a human wouldn't add or is inconsistent with the rest of the file
   - Extra defensive checks or try/catch blocks that are abnormal for that area of the codebase (especially if called by trusted/validated codepaths)
   - Casts to `any` to get around type issues
   - Any other style that is inconsistent with the file

## Phase 3: Commit with git-agent
1. Derive a one-sentence intent from the changes analyzed in Phase 2
2. Determine the correct Claude model name for co-author attribution
   - Valid models: Claude Sonnet 4.6, Claude Opus 4.6, Claude Haiku 4.5
3. Run: `git-agent commit --intent "<intent>" --co-author "Claude <Model> <Version> <noreply@anthropic.com>"`
4. On auth error (401 / missing key), retry with `--free`:
   `git-agent commit --intent "<intent>" --co-author "..." --free`
5. **Fallback** (git-agent unavailable): manual `git commit` with Conventional Commits format
   - Title: `<type>(<scope>): <description>` (lowercase, <=50 chars, no period)
   - Body: bullet points (`- ` prefix, imperative, <=72 chars) + explanation paragraph
   - Footer: `Co-Authored-By: <Model> <noreply@anthropic.com>`
   - Use HEREDOC: `git commit -m "$(cat <<'EOF' ... EOF)"`

If no changes, report "No changes to commit" and exit.
```

**Execute**: Launch a general-purpose agent using the prompt template above
