# GitHub Issue Resolution with Git Worktree

Resolve issues using isolated worktrees, TDD approach, and protected PR workflow with automated issue closure.

## Prerequisites
- `gh` CLI authenticated
- **Commit Requirements:**
  - Commit message title must be entirely lowercase
  - Title must be less than 50 characters
  - Follow conventional commits format (feat:, fix:, chore:, etc.)
  - Use atomic commits for logical units of work
- Protected branches require PR + review + CI
- No direct pushes to main/develop

## Workflow

1. **Select issue** - View all open issues by priority and choose next one to resolve
2. **Create worktree** - Set up isolated workspace with feature branch 
3. **TDD implementation** - Plan with @tech-lead-reviewer, red-green-refactor cycle, review with agents, commit changes
4. **PR creation** - Run quality checks, push branch, open PR with auto-closing keywords
5. **Cleanup** - Remove worktree after merge

## Branch Detection & Workflow

Check current branch and existing worktrees:
```bash
# Check current branch and worktree status
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: $CURRENT_BRANCH"

if [[ "$CURRENT_BRANCH" == "develop" || "$CURRENT_BRANCH" == "main" ]]; then
    echo ""
    echo "You are on the $CURRENT_BRANCH branch."
    echo "Existing worktrees:"
    git worktree list
    echo ""
    echo "Do you want to:"
    echo "1. Continue working on an existing worktree issue"
    echo "2. Create a new worktree for a new issue"
    echo ""
    read -p "Enter choice (1/2): " choice
    
    if [[ "$choice" == "1" ]]; then
        echo "Available worktrees with unfinished issues:"
        git worktree list | grep -v "$(pwd)" | while read worktree_path branch_info; do
            if [[ -d "$worktree_path" ]]; then
                cd "$worktree_path" 2>/dev/null
                if [[ $? -eq 0 ]]; then
                    ISSUE_NUM=$(basename "$worktree_path" | sed 's/.*-worktree-//')
                    echo "- Issue #$ISSUE_NUM: $worktree_path"
                fi
            fi
        done
        echo ""
        echo "To continue working on an existing issue:"
        echo "  cd ../<PROJECT>-worktree-<ISSUE_NUMBER>"
        echo "  claude"
        echo "  /gh/resolve-issues"
        exit 0
    fi
fi
```

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
# Use AI to generate a concise, descriptive branch name
BRANCH_NAME=$(gh issue view $ISSUE_NUMBER --json title,body | jq -r '.title + " " + (.body // "")' | head -c 200 | claude-code --prompt "Generate a concise git branch name (2-4 words, kebab-case) for this issue. Return only the branch name without prefix:" || echo "issue-$ISSUE_NUMBER")
WORKTREE_NAME="$ORIGINAL_DIR-worktree-$ISSUE_NUMBER"
git worktree add "../$WORKTREE_NAME" -b "feature/$ISSUE_NUMBER-$BRANCH_NAME" "origin/$BASE_BRANCH"

# Restart Claude Code session in the new worktree
echo "Worktree created. Restart Claude Code session with:"
echo "  cd ../$WORKTREE_NAME"
echo "  claude"
echo ""
echo "Then continue with: /gh/resolve-issues"
exit 0
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
git worktree remove "../$ORIGINAL_DIR-worktree-$ISSUE_NUMBER"
```

## Key Principles

- **TDD first** - Write failing test before implementation
- **Agent-assisted** - Use specialized agents for planning, review, and refactoring  
- **Atomic commits** - One logical change per commit following standardized requirements:
  - Commit message title must be entirely lowercase
  - Title must be less than 50 characters
  - Follow conventional commits format (feat:, fix:, chore:, etc.)
  - Use atomic commits for logical units of work
- **Protected workflows** - All changes via PR with review and CI checks
- **Isolated development** - Use worktrees to avoid context switching

## Branch Naming

AI generates concise, descriptive names:
- `feature/123-webxr-fallback` - New functionality
- `fix/456-auth-redirect` - Bug fixes  
- `refactor/789-api-cleanup` - Code improvements

## Auto-Closing Keywords

Use in PR body to auto-close issues: `fixes`, `closes`, `resolves`