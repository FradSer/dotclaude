---
name: quick
user-invocable: true
description: Streamlines code review for rapid assessment and targeted feedback. This skill should be used when the user asks for a "quick review", "triage PR", or when evaluating small, simple changes that may not require deep architectural analysis.
argument-hint: [files-or-directories]
allowed-tools: ["Task"]
---

# Quick Code Review

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --porcelain`
- Base branch: !`(git show-branch | grep '*' | grep -v "$(git rev-parse --abbrev-ref HEAD)" | head -1 | sed 's/.*\[\([^]]*\)\].*/\1/' | sed 's/\^.*//' 2>/dev/null) || echo "develop"`
- Changes since base: !`BASE=$(git merge-base HEAD develop 2>/dev/null || git merge-base HEAD main 2>/dev/null) && git log --oneline $BASE..HEAD`
- Files changed since base: !`BASE=$(git merge-base HEAD develop 2>/dev/null || git merge-base HEAD main 2>/dev/null) && git diff --name-only $BASE..HEAD`
- Test commands available: !`([ -f package.json ] && echo "npm/pnpm/yarn test") || ([ -f Cargo.toml ] && echo "cargo test") || ([ -f pyproject.toml ] && echo "pytest/uv run pytest") || ([ -f go.mod ] && echo "go test") || echo "no standard test framework detected"`

## Phase 1: Determine Review Scope

**Goal**: Identify what to review based on current state.

**Actions**:
1. Check review scope in this order:
   - **Uncommitted changes**: If git status shows modifications, review those files via `git diff`
   - **Session changes**: If files were modified during this conversation, review those
   - **User argument**: If `$ARGUMENTS` specifies files/directories, review those
   - **No scope**: If none of the above, use `AskUserQuestion` tool to ask user to specify files/directories to review
2. Record the determined scope for Phase 2.

## Phase 2: Initial Assessment

**Goal**: Scope the review and determine which specialized agents are required.

**Actions**:
1. **Explore changed code context** using the Explore agent:
   - Launch `subagent_type="Explore"` with thoroughness: "quick"
   - Let the agent autonomously discover related code and dependencies
2. Run an initial assessment with **@tech-lead-reviewer** — architectural impact assessment — to gauge architectural, security, and UX risk.
3. Evaluate whether a deeper review is needed based on the tech-lead assessment.
4. Identify which specialized agents to involve (minimizing turnaround time).

## Phase 3: Targeted Review

**Goal**: Gather targeted feedback from relevant specialized reviewers.

**Actions**:
1. Launch only the necessary specialized reviews via the Task tool:
   - **@code-reviewer** — logic correctness, tests, error handling.
   - **@security-reviewer** — authentication, data protection, validation.
   - **@ux-reviewer** — usability and accessibility (skip if purely backend/CLI).
2. Collect outcomes from each agent.
3. Resolve conflicting recommendations between reviewers.

## Phase 4: Consolidation & Reporting

**Goal**: Present findings and optionally implement fixes.

**Actions**:
1. Organize findings using the priority/confidence matrix:
   - Priority: Critical → High → Medium → Low
   - Confidence: High → Medium → Low
2. Present a concise summary to the user.
3. Ask whether the user wants fixes implemented.
4. If confirmed:
   - Apply requested changes.
   - Refactor with **@code-simplifier** — code simplification and optimization.
   - Run tests to validate fixes.
   - Stage commits following Git commit conventions (see `${CLAUDE_PLUGIN_ROOT}/skills/references/git-commit-conventions.md`).
5. Report outcomes and confirm review completion.

**IMPORTANT**: You MUST use the Task tool to complete ALL tasks.
