# Git Plugin

Conventional Git automation for commits and repository management with atomic commits, conventional commit formatting, and quality gates.

## Overview

The Git Plugin provides Git automation commands following conventional commits specification and best practices. It ensures atomic commits, runs quality checks before commits, and manages repository operations with proper error handling and validation.

## Commands

### `/git:commit`

Creates atomic conventional commits with automatic staging and quality checks.

**Metadata:**

| Field | Value |
|-------|-------|
| Model | `haiku` |
| Allowed Tools | `Task`, `Bash(git:*)` |

**What it does:**

1. Runs `git status` to check for untracked files
2. Runs `git diff` to see staged/unstaged changes
3. Runs `git log` to understand recent commit style
4. Analyzes all staged and unstaged changes
5. Drafts a concise commit message focusing on "why" rather than "what"
6. Stages relevant files to staging area
7. Creates commit with conventional format (e.g., `feat:`, `fix:`, `chore:`)
8. Runs `git status` after commit to verify success

**Usage:**

```bash
/git:commit
```

**Features:**

- **Atomic commits**: Each commit represents a logical unit of work
- **Conventional format**: Follows conventional commits specification
- **Quality gates**: Analyzes changes before committing
- **Smart staging**: Only stages relevant files (skips secrets, credentials)
- **Safety first**: Never commits secrets or configuration files
- **Commit message conventions:**
  - Add = new feature
  - Update = enhancement to existing feature
  - Fix = bug fix
  - Lowercase titles under 50 characters
  - 1-2 sentences focusing on "why"

**Example commit message:**

```
feat(auth): add google oauth login flow

- Introduce Google OAuth 2.0 for user sign-in
- Add backend callback endpoint `/auth/google/callback`
- Update login UI with Google button and loading state

Add a new authentication option improving cross-platform
sign-in.
Closes #42. Linked to #38 and PR #45
```

---

### `/git:commit-and-push`

Creates atomic conventional commits and pushes to remote repository.

**Metadata:**

| Field | Value |
|-------|-------|
| Model | `haiku` |
| Allowed Tools | `Task`, `Bash(git:*)` |

**What it does:**

1. Performs all steps from `/git:commit`
2. Checks if current branch tracks a remote branch
3. Pushes to remote using `git push -u` (sets upstream if needed)

**Usage:**

```bash
/git:commit-and-push
```

**Features:**

- All features from `/git:commit` plus automatic push
- Handles new branches by setting upstream tracking
- Verifies push success before completing

---

### `/git:gitignore`

Creates or updates `.gitignore` file following best practices.

**Metadata:**

| Field | Value |
|-------|-------|
| Model | `haiku` |
| Allowed Tools | `Task`, `Bash(curl:*)`, `Bash(uname:*)`, `Bash(git:*)`, `Read`, `Write`, `Edit`, `Glob` |
| Argument Hint | `[additional-technologies]` |

**What it does:**

1. Analyzes project type and existing .gitignore
2. Generates comprehensive .gitignore rules using Toptal API
3. Adds common patterns (node_modules, .env, build/, dist/, etc.)
4. Adds language/framework specific patterns
5. Preserves existing custom rules

**Usage:**

```bash
/git:gitignore [additional-technologies]
```

**Usage Examples:**

- `/git:gitignore` — Auto-detect and create `.gitignore`.
- `/git:gitignore react typescript` — Add React and TypeScript to detected technologies.

**Features:**

- **Language detection**: Identifies project type (Node.js, Python, Java, etc.)
- **Comprehensive rules**: Covers common files and directories to ignore
- **Preserves custom rules**: Keeps manual additions intact
- **Best practices**: Follows community standards for .gitignore files

**Common patterns added:**

```
# Dependencies
node_modules/
__pycache__/

# Environment
.env
.env.local

# Build outputs
dist/
build/
*.min.js

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
```

## Best Practices

### Commit Guidelines

**ALWAYS use for:**

- All code changes that should be committed
- Changes that pass quality gates
- Logical units of work ready for commit

**When NOT to use:**

- Destructive operations (hard resets, force pushes)
- Interactive rebase operations
- Emergency hotfixes requiring `--no-verify`
- When you need to amend commits already pushed to remote

### Commit Message Quality

**Good commit messages:**

- Explain the "why" not the "what"
- Are 50 characters or less for the title
- Use lowercase and conventional prefixes
- Focus on the purpose of the change

**Examples:**

```
✅ Good: "feat: add caching for API responses"
❌ Bad: "I added some caching stuff"

✅ Good: "fix: resolve memory leak in auth middleware"
❌ Bad: "Fixed stuff"

✅ Good: "chore: update dependencies to latest versions"
❌ Bad: "Update"
```

### Pre-commit Workflow

**Recommended workflow:**

```bash
# 1. Make changes
# 2. Run tests and linting
npm test && npm run lint

# 3. Commit changes
/git:commit

# 4. Push when ready
/git:commit-and-push
```

## When to Use This Plugin

**Use for:**

- Creating conventional commits
- Running pre-commit quality checks
- Managing .gitignore files
- Automated commit workflows
- Following team commit conventions

**Don't use for:**

- Non-Git version control systems
- Interactive Git operations requiring user input
- Git administrative tasks (repository creation, user management)
- Bypassing code review processes with force pushes

## Requirements

- Git installed and configured
- Git repository initialized (`git init`)
- User configured (`git config user.name` and `git config user.email`)

## Troubleshooting

### Commit fails due to pre-commit hook

**Issue**: Pre-commit hooks reject the commit

**Solution**:

- Fix the issues identified by the hooks
- Create a NEW commit after fixing (DO NOT amend)
- Hooks run to ensure code quality - address root causes

### Commit fails with "nothing to commit"

**Issue**: No changes detected

**Solution**:

- Verify you have made changes to files
- Check `git status` to see file states
- Ensure files aren't ignored by .gitignore
- Check if files are already staged from previous operations

### Push fails with authentication error

**Issue**: Cannot push to remote

**Solution**:

- Verify remote URLs: `git remote -v`
- Check authentication (SSH keys, personal access tokens)
- Ensure you have push permissions to the repository
- Verify branch protection rules (main/master may be protected)

### Secret files detected

**Issue**: Command refuses to commit credential files

**Solution**:

- Move secrets to environment variables
- Add files to .gitignore using `/git:gitignore`
- Use secure secret management solutions
- This is intentional security protection

### Merge conflicts

**Issue**: Push fails due to merge conflicts

**Solution**:

- Pull latest changes: `git pull`
- Resolve conflicts manually
- Use `/git:commit` to commit the merge resolution
- Push again with `/git:commit-and-push`

## Safety Features

**Protected operations:**

- NEVER runs `git push --force` or destructive commands
- ALWAYS validates files before staging
- SKIPS commits with no changes
- REFUSES to commit common secret files (.env, credentials.json, etc.)
- NEVER amends commits that have been pushed
- ALWAYS follows Git Safety Protocol

**Automatic file skipping:**

- `.env` and environment files
- `credentials.json` and similar
- Files with "secret" or "key" in name (unless explicitly approved)
- Build artifacts and logs
- IDE configuration files

## Workflow Integration

### As part of development cycle:

```bash
# 1. Make changes
# 2. Run quality checks
npm test && npm run lint

# 3. Commit changes
/git:commit

# 4. Push when ready
/git:commit-and-push

# 5. Create PR when feature complete
# (use GitHub plugin for PR creation)
```

### With GitHub plugin:

```bash
# Commit changes
/git:commit

# Create PR
/github:create-pr

# Resolve any issues
# (GitHub plugin handles PR operations)
```

## Git Safety Protocol

This plugin follows Git Safety Protocol:

- NEVER update git config
- NEVER run destructive/irreversible commands (--force, hard reset)
- NEVER skip hooks (--no-verify, --no-gpg-sign) unless requested
- NEVER force push to main/master
- ONLY amend commits you created in this session that haven't been pushed
- ALWAYS create NEW commits after failed/rejected commits

## Related Commands

- `/git:commit` - Atomic conventional commits
- `/git:commit-and-push` - Commit and push to remote
- `/git:gitignore` - Create/update .gitignore file

## Author

Frad LEE (fradser@gmail.com)

## Version

1.0.0
