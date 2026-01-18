---
name: Git Workflow Best Practices
description: This skill should be used when the user asks about "git best practices", "conventional commits", "commit message guidelines", "atomic commits", "git workflow", "how to write commit messages", "commit format", or needs guidance on Git operations following conventional commits specification and safety protocols.
version: 1.0.0
---

# Git Workflow Best Practices

## Purpose

Provide comprehensive guidance on Git workflow best practices, focusing on atomic commits, conventional commit formatting, and safe Git operations. This skill enables consistent, high-quality version control practices aligned with industry standards and team collaboration requirements.

## Core Principles

### Atomic Commits

Atomic commits represent single, complete, cohesive changes. Each commit should:

- Address one logical unit of work
- Be independently revertible without breaking functionality
- Have all necessary changes for that unit (no partial implementations)
- Pass tests and quality gates when applied alone

**When to split commits:**
- Multiple unrelated bug fixes → Separate commits per bug
- Feature + refactoring → Feature commit, then refactoring commit
- Multiple features → One commit per feature
- Bug fix + new feature → Separate commits

**When to combine into one commit:**
- Feature implementation + its tests
- Code change + corresponding documentation update
- Refactoring + fixing bugs revealed by refactoring (if tightly coupled)

### Conventional Commits

Conventional commits follow a standardized format that communicates the nature and scope of changes:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Essential types:**
- `feat:` - New feature or capability
- `fix:` - Bug fix
- `chore:` - Maintenance tasks (dependencies, tooling)
- `docs:` - Documentation changes
- `refactor:` - Code restructuring without behavior change
- `test:` - Adding or updating tests
- `perf:` - Performance improvements
- `style:` - Code formatting, whitespace (no logic change)
- `ci:` - CI/CD configuration changes
- `build:` - Build system changes

**Scope (optional):** Noun identifying the affected component (auth, api, ui, cli)

**Subject line rules:**
- Entirely lowercase
- Under 50 characters
- Imperative mood: "add" not "added" or "adds"
- No period at end
- Focus on "what" not "how"

**Body (optional but recommended):**
- Blank line after subject
- Maximum 72 characters per line
- Start with uppercase letter
- Explain "what" and "why", not "how"
- Use bullet points for multiple changes
- Standard capitalization and punctuation

**Footer (optional):**
- Reference issues and PRs
- Document breaking changes
- Start with uppercase letter

For comprehensive conventional commits specification, see `references/conventional-commits.md`.

### Git Safety Protocol

Safe Git operations prevent destructive changes and protect repository integrity:

**Never:**
- Update git config without explicit user request
- Run destructive commands (`--force`, `git reset --hard`)
- Skip hooks (`--no-verify`, `--no-gpg-sign`) unless requested
- Force push to main/master branches
- Amend commits already pushed to remote
- Commit without analyzing changes first

**Always:**
- Create NEW commits after failures (never amend)
- Validate files before staging
- Check for secrets and credentials
- Review changes with `git status` and `git diff`
- Run quality gates before committing
- Use conventional commit format
- Document breaking changes in footer

For complete safety guidelines, see `references/safety-protocol.md`.

## When to Use This Skill

This skill activates when users need guidance on:

- **Commit message formatting**: Writing effective conventional commits
- **Atomic commit practices**: Splitting or combining changes appropriately
- **Git workflow questions**: Best practices for branching, staging, committing
- **Safety concerns**: Avoiding destructive or dangerous Git operations
- **Commit message quality**: Improving clarity and consistency
- **Team conventions**: Establishing or following Git standards

## How to Use This Skill

### Quick Reference

For immediate commit formatting guidance:

1. **Determine commit type**: feat, fix, chore, docs, refactor, test, perf
2. **Identify scope**: Component or area affected (optional)
3. **Write subject**: Lowercase, imperative, under 50 chars
4. **Add body**: Explain why, not how (optional but recommended)
5. **Include footer**: Reference issues, note breaking changes (optional)

### Detailed Guidance

For in-depth understanding of specific topics:

- **Conventional Commits Specification** → `references/conventional-commits.md`
  - Complete format specification
  - All commit types with examples
  - Scope conventions
  - Breaking change documentation
  - Footer format for issue references

- **Atomic Commit Patterns** → `references/atomic-commits.md`
  - Identifying logical units of work
  - Splitting vs. combining commits
  - Testing atomicity
  - Common patterns and anti-patterns
  - Refactoring commit strategies

- **Git Safety Protocol** → `references/safety-protocol.md`
  - Prohibited operations
  - Required safeguards
  - Secret detection patterns
  - Recovery procedures
  - Pre-commit validation

### Working Examples

The `examples/` directory (at plugin root) contains executable shell scripts demonstrating:

- **`examples/feat-commit-example.sh`** - Feature addition workflow
- **`examples/fix-commit-example.sh`** - Bug fix workflow
- **`examples/breaking-change-example.sh`** - Breaking change documentation
- **`examples/multi-commit-workflow.sh`** - Multiple atomic commits

These scripts show real-world commit sequences with proper formatting and atomic separation.

## Commit Message Quality

### Good Commit Messages

Effective commit messages communicate intent and context:

```
feat(auth): add oauth 2.0 google login

- Implement Google OAuth 2.0 authentication flow
- Add callback endpoint /auth/google/callback
- Update login UI with Google sign-in button

Provides alternative authentication method for users
without email/password accounts.

Closes #42. Linked to #38 and PR #45
```

**Why it's good:**
- Clear type and scope
- Concise subject under 50 chars
- Bullet points explain what changed
- Body explains why (business value)
- Footer references related issues

### Common Mistakes

Avoid these anti-patterns:

❌ **Too vague:**
```
fix: fix bug
chore: update stuff
feat: changes
```

❌ **Wrong tense/mood:**
```
feat: adds new feature
fix: fixed the bug
refactor: refactored code
```

❌ **Subject too long:**
```
feat: add comprehensive user authentication system with oauth support
```

❌ **No type prefix:**
```
Add user login
```

❌ **Missing context:**
```
fix: handle null
```

**Improved versions:**
```
fix(api): handle null payload in session refresh
feat(auth): add oauth 2.0 support
refactor(db): extract query builder to separate module
```

## Workflow Integration

### Pre-Commit Workflow

Recommended sequence for quality commits:

1. **Make changes** - Implement feature or fix
2. **Run tests** - Ensure nothing breaks
3. **Run linters** - Maintain code quality
4. **Review diff** - Understand what changed
5. **Stage files** - Add relevant changes only
6. **Craft message** - Follow conventional format
7. **Commit** - Create atomic commit
8. **Verify** - Check with `git log` and `git show`

### Multi-Commit Workflow

For complex changes requiring multiple commits:

1. **Identify logical units** - Break work into atomic pieces
2. **Prioritize order** - Foundational changes first
3. **Commit iteratively** - One unit at a time
4. **Maintain atomicity** - Each commit should build correctly
5. **Link related commits** - Reference previous commits in messages

See `references/atomic-commits.md` for detailed multi-commit strategies.

### Branch Workflow

**Feature branches:**
- Branch from main/develop
- Use descriptive names (feature/oauth-login, fix/null-pointer)
- Commit atomically on feature branch
- Keep commits focused and conventional
- Squash only if team policy requires it

**Commit frequency:**
- Commit after completing each logical unit
- Don't wait until feature is complete
- Create checkpoints with atomic commits
- Push regularly to backup work

## Additional Resources

### Reference Files

For detailed patterns and specifications, consult:

- **`references/conventional-commits.md`** - Complete conventional commits specification with all types, scope conventions, and extensive examples
- **`references/atomic-commits.md`** - Atomic commit patterns, splitting strategies, and multi-commit workflows
- **`references/safety-protocol.md`** - Comprehensive Git safety guidelines and prohibited operations

### Example Scripts

Working examples demonstrating proper workflows:

- **`examples/feat-commit-example.sh`** - Feature commit workflow
- **`examples/fix-commit-example.sh`** - Bug fix commit workflow
- **`examples/breaking-change-example.sh`** - Breaking change documentation
- **`examples/multi-commit-workflow.sh`** - Multiple atomic commits in sequence

All examples are executable and demonstrate real-world scenarios.

## Quick Decision Guide

**Choosing commit type:**
- New functionality → `feat:`
- Fixing broken behavior → `fix:`
- Improving working code → `refactor:` or `perf:`
- Updating docs only → `docs:`
- Changing build/deploy → `build:` or `ci:`
- Maintenance/cleanup → `chore:`
- Adding/updating tests → `test:`

**Determining atomicity:**
- Can this be reverted independently? → Atomic
- Does this mix multiple concerns? → Split it
- Is this a partial implementation? → Complete it or don't commit
- Do all changes relate to one goal? → Keep together

**Ensuring safety:**
- Are there secrets in changes? → Don't commit
- Did pre-commit hooks fail? → Fix and create new commit
- Has this commit been pushed? → Don't amend
- Is this a destructive operation? → Confirm necessity

## Integration with Git Plugin Commands

This skill complements the git plugin commands:

- **`/git:commit`** - Uses these practices automatically
- **`/git:commit-and-push`** - Applies safety protocol and conventional format
- **`/git:gitignore`** - Ensures secrets never reach staging area

Commands implement these best practices, while this skill provides the knowledge foundation for understanding and extending Git workflows.
