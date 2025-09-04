# GitHub Pull Request Creation

Claude Code workflow for creating comprehensive, secure pull requests using systematic task management and parallel execution.

## Overview

This workflow demonstrates Claude Code best practices: Task/TodoWrite tool integration, parallel execution, and systematic quality validation. It replaces complex scripts with intelligent tool orchestration.

## Claude Code Workflow

### Step 1: Task Planning
Use TodoWrite to create comprehensive task list:

```
1. Validate repository state and authentication
2. Gather change information with parallel execution
3. Run concurrent quality checks
4. Discover and link related issues
5. Generate and create pull request
```

### Step 2: Parallel Validation
Use single message with multiple Bash tool calls:

```bash
# Concurrent repository validation:
git status --porcelain
git branch --show-current
git log @{u}..HEAD --oneline
gh auth status
```

### Step 3: Change Analysis
Execute parallel information gathering:

```bash
# Concurrent change analysis:
git fetch origin main --quiet
git diff --name-only origin/main..HEAD
git diff --stat origin/main..HEAD
git log origin/main..HEAD --oneline
```

### Step 4: Quality Validation
Run concurrent quality checks based on project type:

**Node.js Projects:**
```bash
# Parallel quality checks:
pnpm run lint
pnpm run test
pnpm run build
pnpm run type-check
```

**Python Projects:**
```bash
# Parallel quality checks:
ruff check .
black --check .
pytest
mypy .
```

### Step 5: Security Scanning
Use Grep tool for intelligent security detection:

```
# Security file detection:
Grep: pattern="\.env|\.key|\.pem|secret|password|token" output_mode="files_with_matches"
```

### Step 6: Issue Discovery
Parallel issue correlation:

```bash
# Concurrent issue discovery:
gh issue list --state open --limit 20 --json number,title
git log origin/main..HEAD --pretty=format:"%s"
```

### Step 7: PR Creation
Generate and create PR with parallel operations:

```bash
# Parallel PR preparation:
git push -u origin HEAD
git diff --stat origin/main..HEAD
git log -1 --pretty=format:"%s"
```

## Quality Standards

### Pre-Creation Requirements
- All linting must pass
- All tests must pass
- Build must succeed
- Security scan clean
- Working directory clean

### Task Tool Integration
When quality checks fail:

1. **TodoWrite**: Create specific task list for failed checks
2. **Task tool**: Use specialized agents (code-reviewer, security-reviewer)
3. **Fix systematically**: Address each task with validation
4. **Mark completed**: Update task status immediately
5. **Retry**: Re-run quality checks until all pass

## PR Template

### Title Requirements
- ≤70 characters
- Imperative mood
- No emojis
- Descriptive and clear

### Body Structure
```markdown
## Summary
[Business impact and technical overview]

## Changes
- [Commit-by-commit breakdown]

## Related Issues
Fixes #123

## Security Checklist
- [ ] No secrets or sensitive data exposed
- [ ] Input validation implemented
- [ ] Authentication/authorization proper
- [ ] Dependencies vulnerability-free

## Testing Checklist
- [ ] Unit tests added/updated
- [ ] All existing tests pass
- [ ] Manual testing completed
- [ ] Edge cases tested

## Quality Assurance
- [ ] Linting passed
- [ ] Type checking passed
- [ ] Build successful
- [ ] Code review ready

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update
```

## Failure Resolution

### Quality Check Failures
1. **Identify**: Specific failure category
2. **Task**: Create structured TodoWrite task list
3. **Resolve**: Use Task tool for systematic fixes
4. **Validate**: Re-run checks after each fix
5. **Retry**: Proceed only after all checks pass

### Example Task Resolution
```
Failed linting → TodoWrite task → Task tool (code-reviewer) → Fix → Validate → Mark completed
```

## Quick Reference

### Common Commands
```bash
# Repository validation
git status && gh auth status

# Change analysis  
git diff --stat origin/main..HEAD

# Quality checks (Node.js)
pnpm run lint && pnpm run test && pnpm run build

# PR creation
gh pr create --title "Title" --body-file pr-body.md
```

### Automatic Labels
- `testing` - Test file changes
- `documentation` - Documentation updates
- `dependencies` - Package file changes
- `security` - Security-related changes

### Best Practices
- **Security-first**: Comprehensive security validation
- **Quality gates**: All checks must pass
- **Task integration**: Systematic issue resolution
- **Parallel execution**: Optimize tool calls
- **Small PRs**: Focused, reviewable changes
- **Clear titles**: Descriptive, ≤70 characters