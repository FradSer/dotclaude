# Workflow Details

## Issue Selection

Evaluate open issues from context and prioritize the next actionable item:
- Check issue labels for priority (priority:high, priority:medium, priority:low)
- Review issue description for complexity and dependencies
- Confirm issue is not blocked by other open issues
- Verify issue has clear acceptance criteria

## Worktree Setup

Create an isolated worktree session using the EnterWorktree tool:

1. **Create worktree session**:
   Use the EnterWorktree tool with a descriptive name (e.g., `fix-456-auth-redirect`). This creates a worktree in `.claude/worktrees/` and switches the session into it automatically. `.claude/worktrees/` must be ignored in the repo's tracked `.gitignore` (not only a local `.git/info/exclude` entry) so a fresh clone doesn't show the worktree directory as untracked — verify with `git check-ignore -v .claude/worktrees` before relying on it.

2. **Rename branch to match conventions**:
   EnterWorktree generates a branch named `worktree-<name>`. Rename it before committing:
   ```bash
   git branch -m fix/456-auth-redirect
   ```

3. **Branch naming convention**:
   - Bug fixes: `fix/ISSUE-short-description` (e.g., `fix/456-auth-redirect`)
   - Features: `feat/ISSUE-short-description` (e.g., `feat/123-oauth-login`)
   - Refactoring: `refactor/ISSUE-short-description`

4. **Existing worktree reuse**:
   - Check existing worktrees using `git worktree list`
   - If a worktree already exists for the issue, navigate to it directly instead of creating a new one

## TDD Implementation Cycle

Follow the red-green-refactor cycle with agent collaboration:

1. **Plan implementation**:
   - Assess architectural impact of the change
   - Identify potential design issues or anti-patterns
   - Plan the implementation approach

2. **Red Phase**: Write failing tests
   - Create test cases that verify issue is fixed
   - Run tests to confirm they fail as expected

3. **Green Phase**: Implement minimal fix
   - Write code to make tests pass
   - Focus on solving the problem, not optimization

4. **Refactor Phase**:
   - Simplify and optimize code
   - Remove duplication and improve readability
   - Ensure tests still pass after refactoring

## Quality Validation

During the TDD cycle, run project-specific quality checks:
- Lint: `npm run lint` or `pnpm lint` (Node.js) / `ruff check .` (Python)
- Test: `npm test` or `pnpm test` (Node.js) / `pytest` (Python)
- Build: `npm run build` or `pnpm build` (Node.js)
- Type Check: `npm run type-check` (Node.js) / `mypy .` (Python)

`/github:create-pr` re-runs the full quality and security gate before it opens the PR, so these checks are for fast local feedback, not the gate itself.

## PR Creation and Cleanup

1. **Push branch**: `git push -u origin <branch-name>`
2. **Create PR**: **CRITICAL: never call `gh pr create` from this skill.** Invoke `Skill("github:create-pr", "Closes #456")` with the issue reference. `/github:create-pr` is the plugin's single PR-creating path — it runs the quality/security gate, handles auto-closing keywords and the non-default-branch warning, and hands off to `/github:review-pr` for the review → fix → commit+push → wait-for-review loop. Pass `--no-monitor` through only on an explicit user opt-out.
3. **After merge**: `/github:review-pr` owns the merge decision and post-merge hygiene. Once merged, use ExitWorktree action "remove" for the linked worktree — confirm you are still on the issue branch first
   - If uncommitted changes exist, ExitWorktree will refuse; confirm with the user before setting `discard_changes: true`
