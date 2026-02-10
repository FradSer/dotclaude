# Git Commit - Detailed Guidance

## Goal

Commit the plan folder to git with a proper commit message.

## Actions

### 1. Commit Plan to Git

**CRITICAL: You MUST commit the entire folder, not just individual files**

**Commit Pattern**:

```bash
git add docs/plans/YYYY-MM-DD-<topic>-plan/
git commit -m "docs: add implementation plan for <topic>

<Context>

- <Specific action taken>
- <Specific action taken>

<Summary>

Co-Authored-By: <Model Name> <noreply@anthropic.com>"
```

**Commit Message Requirements**:

- **Prefix**: `docs:` (lowercase)
- **Subject**: Short description under 50 characters, lowercase
- **Body**:
  - Feature context or brief description
  - Specific actions taken (as a bulleted list)
  - Brief summary of the plan approach
- **Footer**: `Co-Authored-By: <Model Name> <noreply@anthropic.com>`

**Example**:

```bash
git commit -m "docs: add implementation plan for user authentication

Implementation plan derived from design.

- Decomposed BDD scenarios into 8 granular tasks
- Defined verification steps for each task
- Enforced Test-First (Red-Green) workflow

Summary: Tasks organized in sequential batches following BDD
principles with clear file ownership and verification commands.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

### 2. Verify Commit

Run `git log -1` to confirm the commit was created:

```bash
git log -1
```

Expected output should show:
- The commit with `docs:` prefix
- Proper subject line
- Co-Authored-By footer

### 3. Inform User

Tell the user:
- Plan folder and main document location
- Number of tasks created
- Git commit completed
- Ready to proceed with execution

**Example notification**:

```
Plan created and committed!

Location: docs/plans/2024-02-10-user-auth-plan/
- _index.md: Plan overview with task references
- task-001-setup-project-structure.md: Task 1
- task-002-create-base-auth-handler.md: Task 2
- ...

Total tasks: 8

Git commit completed: docs: add implementation plan for user authentication

Ready to proceed with execution using superpowers:executing-plans.
```

## Output

- Plan folder committed to git with proper message
- Commit verified with `git log -1`
- User informed and ready for execution

## Best Practices

**Commit Quality**:
- Always commit the entire folder using `git add docs/plans/YYYY-MM-DD-<topic>-plan/`
- Use lowercase prefix `docs:` not `Docs:` or `DOCS:`
- Keep subject line under 50 characters
- Include Co-Authored-By footer with model name

**User Communication**:
- Provide full path to plan folder
- List number of tasks created
- Confirm git commit status
- Clear next steps for execution

## Common Pitfalls to Avoid

**Don't commit individual files**:
```bash
# Wrong: Commits only _index.md
git add docs/plans/2024-02-10-plan/_index.md
git commit -m "docs: add plan"

# Correct: Commits entire folder
git add docs/plans/2024-02-10-plan/
git commit -m "docs: add plan"
```

**Don't skip verification**:
```bash
# Always verify commit was created
git log -1
```

**Don't use incorrect prefix**:
```bash
# Wrong
git commit -m "Docs: add plan"
git commit -m "feature: add plan"

# Correct
git commit -m "docs: add plan"
```