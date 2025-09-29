---
allowed-tools: Bash(gh:*), Bash(git:*), Grep, Task, TodoWrite
description: Create comprehensive GitHub pull requests with quality validation
---

## Context

- Current git status: !`git status`
- Current branch: !`git branch --show-current`
- Unpushed commits: !`git log @{u}..HEAD --oneline 2>/dev/null || git log --oneline -5`
- GitHub authentication: !`gh auth status`
- Repository changes: !`git diff --stat HEAD~1..HEAD 2>/dev/null || echo "No recent changes"`

## Your task

**IMPORTANT: You MUST use the Task tool to complete ALL tasks.**

Create comprehensive, secure pull requests using systematic validation and quality checks:

### Workflow Steps

1. **Repository Validation** - Check authentication and branch status
2. **Change Analysis** - Analyze commits and file changes
3. **Quality Validation** - Run project-specific quality checks
4. **Security Scanning** - Check for sensitive data exposure
5. **Issue Discovery** - Find and link related issues
6. **PR Creation** - Generate and create pull request with proper metadata

### Quality Validation Process

**Node.js Projects:**
- Run lint, test, build, and type-check commands
- Validate package.json changes
- Check for security vulnerabilities

**Python Projects:**
- Run ruff, black, pytest, and mypy
- Validate requirements and dependencies
- Check for security issues

### Security Validation

- Scan for sensitive files (.env, .key, .pem)
- Check for hardcoded secrets, passwords, tokens
- Validate input sanitization in changed files
- Ensure no credentials in commit history

### Pre-Creation Requirements

- Repository state validated and clean
- All quality checks passed (lint, test, build)
- Security scan completed without issues
- Related issues identified and linked
- Proper branch naming and commit messages following standards

### Failure Resolution Process

When quality checks fail:
1. Use TodoWrite to create specific task list for failures
2. Use Task tool with specialized agents (code-reviewer, security-reviewer)
3. Fix issues systematically with validation after each fix
4. Mark tasks completed immediately after resolution
5. Re-run quality checks until all pass

### PR Structure Requirements

**Title Guidelines:**
- Maximum 70 characters
- Use imperative mood
- No emojis
- Clear and descriptive

**Body Template:**
```markdown
## Summary
Brief description of changes and business impact

## Changes
- List of key modifications
- Technical details and rationale

## Related Issues
Fixes #123, Closes #456

## Testing
- [ ] Unit tests added/updated
- [ ] All tests pass
- [ ] Manual testing completed
- [ ] Edge cases covered

## Security & Quality
- [ ] No sensitive data exposed
- [ ] Input validation implemented
- [ ] Linting and type checking passed
- [ ] Build successful

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update
```

### Automated Labeling

Labels are automatically applied based on changes:
- `testing` - Test file modifications
- `documentation` - Documentation updates
- `dependencies` - Package file changes
- `security` - Security-related modifications

### Commit Message Validation

Before creating PR, validate all commits follow standards:
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Use atomic commits for logical units of work
- Review all commits in branch for compliance
- Handle non-standard commits by documenting in PR description or interactive rebase if safe

### Best Practices

- **Quality-first**: All checks must pass before PR creation
- **Security validation**: Comprehensive scanning for vulnerabilities
- **Issue linking**: Connect PRs to related issues with auto-closing keywords
- **Small, focused changes**: Easier to review and merge
- **Parallel execution**: Optimize tool calls for efficiency
- **Commit standards**: Validate all commits follow conventional format
