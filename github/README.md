# GitHub Plugin

GitHub project operations with quality gates, TDD workflows, and comprehensive issue management.

## Installation

```bash
claude plugin install github@frad-dotclaude
```

**Requirements:**
- GitHub CLI (`gh`) must be installed and authenticated
- Repository must have a GitHub remote
- Project must have lint, test, and build commands configured
- Git must support worktrees (Git 2.5+)

## Overview

The GitHub Plugin automates GitHub operations including pull request creation, issue management, and quality validation. It ensures all PRs meet quality standards before submission and follows TDD principles with atomic commits and conventional commit formats.

## Commands

### `/github:create-pr`

Creates comprehensive GitHub pull requests with quality validation and gates.

**Metadata:**

| Field | Value |
|-------|-------|
| Allowed Tools | `Task`, `Bash(gh:*)`, `Bash(git:*)` |

**What it does:**
1. Validates repository status and GitHub authentication
2. Analyzes all commits in the branch (full history analysis)
3. Enforces atomic commits: each commit represents one complete, cohesive change
4. Runs comprehensive quality and security checks:
   - Lint validation
   - Test suite execution
   - Build verification
   - Security scanning for sensitive data
5. Validates commit messages follow conventional format:
   - **Format**: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
   - **Title**: lowercase, <50 chars, imperative mood, optional scope
   - **Body**: ≤72 chars per line, describes what and why
   - **Footer**: References issues with auto-closing keywords
6. Ensures all checks pass before PR creation
7. Creates comprehensive PR description with:
   - Summary of changes (1-3 bullet points)
   - Test plan checklist
   - Related issues and PRs
   - Quality validation status
8. Applies automated labels based on changes
9. Creates PR using GitHub CLI with proper metadata

**Usage:**
```bash
/github:create-pr
```

**Example workflow:**
```bash
# Make atomic commits following conventional format
/git:commit  # First feature commit
/git:commit  # Second feature commit

# Create PR with quality gates
/github:create-pr

# Claude will:
# - Validate all commits follow conventional format
# - Run lint, test, build, security checks
# - Ensure all quality gates pass
# - Generate comprehensive PR description
# - Apply labels and link issues
# - Create PR and provide URL
```

**Features:**
- **Quality gates**: All checks must pass before PR creation
- **Atomic commits**: Validates each commit is a logical unit
- **Conventional commits**: Enforces commit message standards
- **Comprehensive validation**: Lint, test, build, security
- **Auto-labeling**: Applies labels based on change types
- **Issue linking**: Automatically links related issues
- **Security scanning**: Checks for sensitive data exposure
- **Failure resolution**: Uses specialized agents to fix issues

**Failure resolution process:**
When quality checks fail, the command:
1. Uses TodoWrite to create specific task lists
2. Invokes specialized agents for fixes:
   - **@code-reviewer** for logic and correctness
   - **@security-reviewer** for security issues
3. Fixes issues systematically with validation
4. Re-runs checks until all pass

---

### `/github:create-issues`

Creates GitHub issues following TDD principles with proper labels, scope, and auto-closing keywords.

**Metadata:**

| Field | Value |
|-------|-------|
| Allowed Tools | `Task`, `Bash(gh:*)`, `Bash(git:*)` |
| Argument Hint | `[description]` |

**What it does:**
1. Analyzes repository context and existing issues
2. Determines issue type (epic, PR-scoped, or review issue)
3. Creates proper labels if they don't exist:
   - `priority:high` - High priority - this sprint
   - `priority:medium` - Medium priority - next sprint
   - `priority:low` - Low priority - backlog
4. Creates issues with required structure:
   - Title (≤70 chars, imperative, no emojis)
   - Proper labels
   - Detailed body with problem description
   - Acceptance criteria
   - Context and links
5. Applies auto-closing keywords for PR-scoped issues
6. Provides issue URLs and tracking information

**Usage:**
```bash
/github:create-issues [\"Bug description\" \"Feature description\"]
```

**Example workflows:**
```bash
# Create single issue
/github:create-issues \"Fix memory leak in auth service\"

# Create multiple issues
/github:create-issues \"Add rate limiting\" \"Update payment API\" \"Fix mobile layout\"

# With detailed description (interactive)
/github:create-issues
# Claude will ask for details and create properly formatted issue
```

**Features:**
- **TDD-first**: Follows test-driven development workflow
- **Branch-aware**: Decision tree based on current branch
- **Proper labeling**: Automatic label assignment
- **Scope determination**: Epic vs PR-scoped issues
- **Auto-closing**: Uses keywords (Closes, Fixes, Resolves)
- **Structured format**: Consistent issue templates

**Branch-based decision logic:**
- **On main/develop**: Create issue directly
- **On PR branch**: Ask "Must this be fixed before merge?"
  - **Yes**: Comment in PR with detailed context
  - **No**: Create new issue for later with justification

**Issue types:**
1. **Epic issues**: Multi-PR initiatives (no auto-close keywords)
2. **PR-scoped issues**: Single PR resolution (use auto-close keywords)
3. **Review issues**: Non-blocking feedback from PR reviews

---

### `/github:resolve-issues`

Resolves GitHub issues using isolated worktrees and TDD workflow with comprehensive quality validation.

**Metadata:**

| Field | Value |
|-------|-------|
| Allowed Tools | `Bash(gh:*)`, `Bash(git:*)`, `Bash(cd:*)`, `Bash(mkdir:*)`, `Task` |

**What it does:**
1. **Issue Selection**: Evaluates open issues and prioritizes next actionable item
2. **Worktree Setup**: Creates or reuses isolated worktree with descriptive branch name
3. **TDD Implementation**:
   - Plan with **@tech-lead-reviewer** for architectural impact
   - Write failing tests (red phase)
   - Implement fixes with **@code-simplifier** for optimization
   - Refactor while keeping tests green
4. **Quality Validation**: Runs project-specific lint, test, and build commands
5. **PR Creation**: Pushes branch and creates PR with auto-closing keywords
6. **Cleanup**: Removes worktree after merge with documentation

**Usage:**
```bash
/github:resolve-issues
```

**Example workflow:**
```bash
# Start issue resolution
/github:resolve-issues

# Claude will:
# - Show open issues and ask which to resolve
# - Create worktree: git worktree add ../fix-123-auth-redirect
# - Plan with tech-lead-reviewer
# - Write failing tests
# - Implement fix
# - Run quality checks
# - Create PR with \"Fixes #123\"
# - Clean up worktree after merge
```

**Features:**
- **Isolated worktrees**: Clean environment for each issue
- **TDD workflow**: Red → Green → Refactor cycle
- **Multi-agent collaboration**: Works with specialized reviewers
- **Quality gates**: All checks must pass
- **Auto-cleanup**: Removes worktrees after completion
- **Documentation**: Tracks all decisions and actions

**Agent collaboration:**
- **@tech-lead-reviewer**: Architectural review and planning
- **@code-simplifier**: Code optimization and simplification
- **@security-reviewer**: Security validation (when applicable)

## Best Practices

### Using `/github:create-pr`
- **Quality-first**: All checks must pass before PR creation
- **Atomic commits**: Each commit should be a logical unit
- **Conventional format**: Follow commit message standards
- **Small PRs**: Easier to review and merge
- **Issue linking**: Reference issues in commits for auto-closing
- **Review the PR**: Verify description accuracy before submission

### Using `/github:create-issues`
- **Clear descriptions**: Provide specific problem statements
- **Acceptance criteria**: Define measurable completion conditions
- **TDD workflow**: Create issues before implementation
- **Proper scoping**: Distinguish between epics and PR-scoped issues
- **Label consistently**: Use priority and type labels
- **Link related items**: Connect issues to related work

### Using `/github:resolve-issues`
- **Select wisely**: Prioritize the next actionable issue
- **Follow TDD**: Write tests before implementation
- **Use worktrees**: Keep environments isolated
- **Collaborate**: Use specialized agents for review
- **Quality gates**: All checks must pass before PR
- **Clean up**: Remove worktrees after merge
- **Document**: Track decisions and lessons learned

## Workflow Integration

### Complete development workflow:
```bash
# 1. Create issue for feature
/github:create-issues \"Add OAuth authentication\"

# 2. Resolve the issue
/github:resolve-issues
# - Select the OAuth issue
# - Work in isolated worktree
# - Follow TDD cycle
# - Create PR when complete

# 3. Or manual development
/git:commit  # Follow conventional format
/git:commit

# 4. Create PR with quality gates
/github:create-pr
# - All checks pass
# - PR description generated
# - Issues linked automatically

# 5. After merge, resolve issues
/github:resolve-issues
# - Issues closed automatically
```

## Requirements

- GitHub CLI (`gh`) must be installed
- GitHub CLI must be authenticated: `gh auth login`
- Repository must have a GitHub remote named `origin`
- Project must have configured lint, test, and build commands
- Git version 2.5+ for worktree support

## Troubleshooting

### `/github:create-pr` fails quality checks

**Issue**: Lint, test, build, or security checks fail

**Solution**:
- Review failure output carefully
- Fix all issues systematically
- For security issues, work with @security-reviewer
- Re-run `/github:create-pr` after all fixes
- Consider splitting large PRs if too many issues

### GitHub CLI not authenticated

**Issue**: `gh` commands fail with authentication error

**Solution**:
- Install GitHub CLI: `brew install gh` (macOS) or see [GitHub CLI installation](https://cli.github.com/)
- Authenticate: `gh auth login`
- Select appropriate authentication method
- Verify with: `gh auth status`
- Ensure repository remote: `git remote -v`

### PR description is incomplete

**Issue**: PR description missing context or details

**Solution**:
- Ensure commits follow conventional format
- Write descriptive commit messages
- Reference issues in commit messages
- Manually edit PR after creation if needed
- Check full commit history for context

### Worktree operations fail

**Issue**: `git worktree` commands fail

**Solution**:
- Update Git to version 2.5+
- Check worktree list: `git worktree list`
- Remove orphaned worktrees: `git worktree remove <path>`
- Clean up with: `git worktree prune`
- Ensure sufficient disk space

### Issue auto-closing doesn't work

**Issue**: Merged PR doesn't close linked issues

**Solution**:
- Use correct keywords: Closes, Fixes, Resolves
- Reference issue in PR or commit message
- Check GitHub repository permissions
- Verify issue exists and is open
- Manually close if needed and update process

## Safety Features

- **Protected branches**: Enforces PR workflow for main/develop
- **Quality gates**: All checks must pass before PR creation
- **Security scanning**: Detects sensitive data before commits
- **Atomic commits**: Validates each commit is a logical unit
- **Worktree isolation**: Prevents repository corruption
- **Atomic PR creation**: Either all succeeds or all fails

## Key Principles

✅ **TDD-First**: Test → Code → Refactor cycle
✅ **Quality Gates**: All checks pass before PR
✅ **Atomic Commits**: One logical change per commit
✅ **Issue-Driven**: Work from well-defined issues
✅ **Collaborative**: Multi-agent review and validation
✅ **Clean Workflow**: Isolated worktrees, automated cleanup

## Author

Frad LEE (fradser@gmail.com)
