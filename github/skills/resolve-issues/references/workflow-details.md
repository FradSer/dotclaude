# Workflow Details

## Issue Selection

Evaluate open issues from context and prioritize the next actionable item:
- Check issue labels for priority (priority:high, priority:medium, priority:low)
- Review issue description for complexity and dependencies
- Confirm issue is not blocked by other open issues
- Verify issue has clear acceptance criteria

## Worktree Setup

Create or reuse an isolated worktree with a descriptive branch name:

1. **New worktree creation**:
   ```bash
   git worktree add ../worktree-fix-456 -b fix/456-auth-redirect
   ```

2. **Branch naming convention**:
   - Bug fixes: `fix/ISSUE-short-description` (e.g., `fix/456-auth-redirect`)
   - Features: `feat/ISSUE-short-description` (e.g., `feat/123-oauth-login`)
   - Refactoring: `refactor/ISSUE-short-description`

3. **Existing worktree reuse**:
   - Check existing worktrees using `git worktree list`
   - Navigate to existing worktree if already created for the issue

## TDD Implementation Cycle

Follow the red-green-refactor cycle with agent collaboration:

1. **Plan with @tech-lead-reviewer**:
   - Assess architectural impact of the change
   - Identify potential design issues or anti-patterns
   - Plan the implementation approach

2. **Red Phase**: Write failing tests
   - Create test cases that verify issue is fixed
   - Run tests to confirm they fail as expected

3. **Green Phase**: Implement minimal fix
   - Write code to make tests pass
   - Focus on solving the problem, not optimization

4. **Refactor Phase with @code-simplifier**:
   - Request code simplification and optimization
   - Remove duplication and improve readability
   - Ensure tests still pass after refactoring

## Quality Validation

Before creating PR, run project-specific quality checks:
- Lint: `npm run lint` or `pnpm lint` (Node.js) / `ruff check .` (Python)
- Test: `npm test` or `pnpm test` (Node.js) / `pytest` (Python)
- Build: `npm run build` or `pnpm build` (Node.js)
- Type Check: `npm run type-check` (Node.js) / `mypy .` (Python)

## PR Creation and Cleanup

1. **Push branch**: `git push -u origin <branch-name>`
2. **Create PR**: Use `gh pr create` with auto-closing keywords (e.g., "Closes #456")
3. **After merge**: Clean up worktree
   ```bash
   git worktree remove ../worktree-fix-456
   git branch -d fix/456-auth-redirect
   ```
