# Git Commit - Detailed Guidance

## Goal

Commit the documentation folder to git with a proper commit message.

## Context

This guide applies to three phases of the development workflow:

| Phase | Folder Type | Subject Template |
|-------|-------------|------------------|
| Brainstorming (Design) | `*-design/` | `docs: add design for ${topic}` |
| Writing Plans | `*-plan/` | `docs: add implementation plan for ${topic}` |
| Executing Plans | Implementation changes | `feat(${scope}): ${description}` |

## Actions

### 1. Commit Folder to Git

**CRITICAL: You MUST commit the entire folder, not just individual files**

**Commit Pattern for Design and Plan Folders**:

```bash
git add docs/plans/${date}-${folder-type}-${topic}/
git commit -m "docs: add ${type} for ${topic}

${context}

- ${specific_action_1}
- ${specific_action_2}

${summary}

Co-Authored-By: ${model_name} <noreply@anthropic.com>"
```

**Commit Pattern for Implementation Changes**:

```bash
git add ${files_to_commit}
git commit -m "feat(${scope}): ${description}

${context}

- ${specific_action_1}
- ${specific_action_2}

${summary}

Co-Authored-By: ${model_name} <noreply@anthropic.com>"
```

**Commit Message Requirements**:

- **Prefix**: `docs:` for design/plan folders, `feat(${scope}):` for implementation
- **Subject**: Short description under 50 characters, lowercase
- **Body**:
  - Context (user request, feature description, or project background)
  - Specific actions taken (as a bulleted list)
  - Brief summary of the approach
- **Footer**: `Co-Authored-By: ${model_name} <noreply@anthropic.com>`

**Example - Design**:

```bash
git commit -m "docs: add design for user authentication

Request: Implement JWT auth for API.

- Explored existing auth in /admin
- Researched JWT best practices via WebSearch
- Created comprehensive design with BDD specs

Summary: Implements stateless JWT auth using existing library with
bearer token validation and refresh token rotation.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

**Example - Implementation Plan**:

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

**Example - Implementation**:

```bash
git commit -m "feat(auth): implement JWT token validation

- Created TokenValidator class with HS256 algorithm
- Added middleware for request header parsing
- Integrated with existing user service

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

### 2. Verify Commit

Run `git log -1` to confirm the commit was created:

```bash
git log -1
```

Expected output should show:
- The commit with correct prefix
- Proper subject line
- Co-Authored-By footer

### 3. Inform User

Tell the user:
- Folder and main document location
- Number of files or tasks created
- Git commit completed
- Clear next steps for the workflow phase

**Example notification (Design)**:

```
Design created and committed!

Location: docs/plans/${date}-${topic}-design/
- _index.md: Main design document
- bdd-specs.md: BDD scenarios
- architecture.md: Architecture details
- best-practices.md: Best practices

Git commit completed: docs: add design for ${topic}

Ready to proceed with implementation using superpowers:writing-plans.
```

**Example notification (Plan)**:

```
Plan created and committed!

Location: docs/plans/${date}-${topic}-plan/
- _index.md: Plan overview with task references
- task-001-setup-project-structure.md: Task 1
- task-002-create-base-auth-handler.md: Task 2
- ...

Total tasks: ${task_count}

Git commit completed: docs: add implementation plan for ${topic}

Ready to proceed with execution using superpowers:executing-plans.
```

**Example notification (Implementation)**:

```
All tasks completed!

Implementation changes committed: feat(${scope}): ${description}

- ${task_count} tasks executed successfully
- All BDD scenarios passing
- Ready for review and testing
```

## Output

- Folder committed to git with proper message
- Commit verified with `git log -1`
- User informed and ready for next workflow phase

## Best Practices

**Commit Quality**:
- Always commit the entire folder using `git add docs/plans/${date}-${type}-${topic}/`
- Use lowercase prefix: `docs:` not `Docs:` or `DOCS:`
- Keep subject line under 50 characters
- Include Co-Authored-By footer with model name

**User Communication**:
- Provide full path to folder
- List key documents created
- Confirm git commit status
- Clear next steps for the workflow

## Common Pitfalls to Avoid

**Don't commit individual files**:
```bash
# Wrong: Commits only _index.md
git add docs/plans/${date}-design/_index.md
git commit -m "docs: add design"

# Correct: Commits entire folder
git add docs/plans/${date}-design/
git commit -m "docs: add design"
```

**Don't skip verification**:
```bash
# Always verify commit was created
git log -1
```

**Don't use incorrect prefix**:
```bash
# Wrong
git commit -m "Docs: add design"
git commit -m "feature: add design"

# Correct
git commit -m "docs: add design"
```