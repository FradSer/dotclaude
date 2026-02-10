# Phase 4: Git Commit - Detailed Guidance

## Goal

Commit the design folder to git with a proper commit message.

## Actions

### 1. Commit Design to Git

**CRITICAL: You MUST commit the entire folder, not just individual files**

**Commit Pattern**:

```bash
git add docs/plans/YYYY-MM-DD-<topic>-design/
git commit -m "docs: add design for <topic>

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
  - User's original request or context
  - Specific actions taken (as a bulleted list)
  - Brief summary of the design approach
- **Footer**: `Co-Authored-By: <Model Name> <noreply@anthropic.com>`

**Example**:

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
- Design folder and main document location
- Git commit completed
- Ready to proceed with implementation following BDD scenarios

**Example notification**:

```
Design created and committed!

Location: docs/plans/2024-02-10-user-auth-design/
- _index.md: Main design document
- bdd-specs.md: BDD scenarios
- architecture.md: Architecture details
- best-practices.md: Best practices

Git commit completed: docs: add design for user authentication

Ready to proceed with implementation using superpowers:writing-plans.
```

## Output

- Design folder committed to git with proper message
- Commit verified with `git log -1`
- User informed and ready for Phase 5

## Best Practices

**Commit Quality**:
- Always commit the entire folder using `git add docs/plans/YYYY-MM-DD-<topic>-design/`
- Use lowercase prefix `docs:` not `Docs:` or `DOCS:`
- Keep subject line under 50 characters
- Include Co-Authored-By footer with model name

**User Communication**:
- Provide full path to design folder
- List all created documents
- Confirm git commit status
- Clear next steps for implementation

## Common Pitfalls to Avoid

**Don't commit individual files**:
```bash
# Wrong: Commits only _index.md
git add docs/plans/2024-02-10-design/_index.md
git commit -m "docs: add design"

# Correct: Commits entire folder
git add docs/plans/2024-02-10-design/
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