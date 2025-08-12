# GitHub Issue Resolution with Git Worktree

Resolve issues using isolated worktrees, TDD approach, and protected PR workflow with automated issue closure.

## Prerequisites
- `gh` CLI authenticated
- Conventional commits (≤50 chars subject, ≤72 chars body) 
- Protected branches require PR + review + CI
- No direct pushes to main/develop

## Workflow

1. **Select issue** - View all open issues by priority and choose next one to resolve
2. **Create worktree** - Set up isolated workspace with feature branch 
3. **TDD implementation** - Plan with @tech-lead-reviewer, red-green-refactor cycle, review with agents, commit changes
4. **PR creation** - Run quality checks, push branch, open PR with auto-closing keywords
5. **Cleanup** - Remove worktree after merge

## Issue Selection

View all open issues prioritized (high → medium → low):
```bash
# View all issues
gh issue list --state open --limit 50
git worktree list
git status
```

## Worktree Setup

Create isolated development environment:
```bash
# Save current directory and determine base branch
ORIGINAL_DIR=$(basename "$PWD")
BASE_BRANCH=$(git ls-remote --heads origin develop >/dev/null 2>&1 && echo "develop" || echo "main")

# Create feature branch in new worktree
ISSUE_SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
git worktree add "../worktree-$ISSUE_NUMBER" -b "feature/$ISSUE_NUMBER-$ISSUE_SLUG" "origin/$BASE_BRANCH"
cd "../worktree-$ISSUE_NUMBER"
```

## TDD Implementation

1. **@tech-lead-reviewer** - Analyze issue scope and implementation strategy
2. **Red** - Add failing test that reproduces issue (don't modify existing tests)
3. **Green** - Implement minimal fix to make test pass
4. **Review** - Use specialized agents:
   - **@code-reviewer** - Comprehensive code review before integration
   - **@security-reviewer** - For auth/sensitive/external-input code  
   - **@ux-reviewer** - For UI/UX-impacting changes
5. **Refactor** - **@code-simplifier** to improve code while keeping tests green
6. **Commit** - Atomic commits following Conventional Commits

## PR Creation

Quality checks before pushing:
```bash
# Run quality checks (adapt commands to project)
pnpm lint
pnpm test  
pnpm build

# Push and create PR
git push -u origin HEAD
gh pr create --title "<PR title>" --body "Fixes #$ISSUE_NUMBER"
```

## Cleanup

After PR merge, remove worktree:
```bash
cd "../$ORIGINAL_DIR"
git worktree remove "../worktree-$ISSUE_NUMBER"
```

## Key Principles

- **TDD first** - Write failing test before implementation
- **Agent-assisted** - Use specialized agents for planning, review, and refactoring  
- **Atomic commits** - One logical change per commit with conventional messages
- **Protected workflows** - All changes via PR with review and CI checks
- **Isolated development** - Use worktrees to avoid context switching

## Branch Naming

- `feature/123-error-boundary` - New functionality
- `fix/456-auth-redirect` - Bug fixes  
- `refactor/789-api-structure` - Code improvements

## Auto-Closing Keywords

Use in PR body to auto-close issues: `fixes`, `closes`, `resolves`