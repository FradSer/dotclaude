---
name: hierarchical
user-invocable: true
description: Performs comprehensive multi-stage code review using specialized subagents. This skill should be used when the user asks to "review PR deeply", "perform a thorough review", or when analyzing pull requests with complex architectural impact or security concerns.
argument-hint: [files-or-directories]
allowed-tools: ["Task"]
---

# Hierarchical Code Review

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --porcelain`
- Base branch: !`(git show-branch | grep '*' | grep -v "$(git rev-parse --abbrev-ref HEAD)" | head -1 | sed 's/.*\[\([^]]*\)\].*/\1/' | sed 's/\^.*//' 2>/dev/null) || echo "develop"`
- Changes since base: !`BASE=$(git merge-base HEAD develop 2>/dev/null || git merge-base HEAD main 2>/dev/null) && git log --oneline $BASE..HEAD`
- Files changed since base: !`BASE=$(git merge-base HEAD develop 2>/dev/null || git merge-base HEAD main 2>/dev/null) && git diff --name-only $BASE..HEAD`
- Test commands available: !`([ -f package.json ] && echo "npm/pnpm/yarn test") || ([ -f Cargo.toml ] && echo "cargo test") || ([ -f pyproject.toml ] && echo "pytest/uv run pytest") || ([ -f go.mod ] && echo "go test") || echo "no standard test framework detected"`

## Phase 1: Technical Leadership Assessment

**Goal**: Map risk areas and determine which specialized agents to involve.

**Actions**:
1. Perform a leadership assessment with **@tech-lead-reviewer** — architectural impact assessment.
2. Evaluate architectural, technical debt, scalability, and maintainability impact.
3. Determine which specialized agents are required based on risk assessment.

## Phase 2: Parallel Specialized Reviews

**Goal**: Collect comprehensive feedback from all relevant specialized reviewers.

**Actions**:
1. Launch required specialized reviews in parallel via the Task tool:
   - **@code-reviewer** — logic correctness, tests, error handling.
   - **@security-reviewer** — authentication, data protection, validation.
   - **@ux-reviewer** — usability and accessibility (skip if purely backend/CLI).
2. Collect outcomes from each agent.
3. Resolve conflicting feedback between reviewers.

## Phase 3: Consolidated Analysis & Reporting

**Goal**: Merge findings and produce prioritized actionable improvements.

**Actions**:
1. Merge findings and prioritize by impact/confidence:
   - Priority: Critical → High → Medium → Low
   - Confidence: High → Medium → Low
2. Present a consolidated report with prioritized recommendations.
3. Ask whether the user wants fixes implemented.
4. If confirmed:
   - Address security, quality, or UX issues as requested.
   - Run tests and validations.
   - Engage **@code-simplifier** — code simplification and optimization — to refactor implemented fixes, remove redundancy, and verify compliance with SOLID principles.
5. Ensure commits follow Git conventions (see `${CLAUDE_PLUGIN_ROOT}/skills/references/git-commit-conventions.md`).
6. Report outcomes and confirm review completion.

**IMPORTANT**: You MUST use the Task tool to complete ALL tasks.
