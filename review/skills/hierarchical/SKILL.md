---
name: hierarchical
user-invocable: true
description: Performs comprehensive project-level review using specialized subagents. This skill should be used when the user asks for a "full review", "project review", "comprehensive audit", or when analyzing entire codebases for quality, security, and architecture.
argument-hint: [directory]
allowed-tools: ["Task"]
---

# Hierarchical Project Review

## Context

- Project root: !`pwd`
- Directory structure: !`find . -type f -name "*.py" -o -name "*.ts" -o -name "*.js" -o -name "*.go" -o -name "*.rs" -o -name "*.java" -o -name "*.swift" 2>/dev/null | head -50`
- Tech stack: !`([ -f package.json ] && echo "Node.js") || ([ -f Cargo.toml ] && echo "Rust") || ([ -f pyproject.toml ] && echo "Python") || ([ -f go.mod ] && echo "Go") || ([ -f pom.xml ] && echo "Java") || ([ -f Package.swift ] && echo "Swift") || echo "Unknown"`
- Test commands available: !`([ -f package.json ] && echo "npm/pnpm/yarn test") || ([ -f Cargo.toml ] && echo "cargo test") || ([ -f pyproject.toml ] && echo "pytest/uv run pytest") || ([ -f go.mod ] && echo "go test") || echo "no standard test framework detected"`
- Total files: !`find . -type f \( -name "*.py" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.go" -o -name "*.rs" -o -name "*.java" -o -name "*.swift" \) 2>/dev/null | wc -l | tr -d ' '`

## Phase 1: Determine Review Scope

**Goal**: Identify the project directory to review.

**Actions**:
1. Check review scope in this order:
   - **User argument**: If `$ARGUMENTS` specifies a directory, review that directory recursively
   - **Current directory**: If no argument, review the current project root (`.`)
2. Confirm scope with user if the project is large (>100 files) to potentially limit scope.

## Phase 2: Technical Leadership Assessment

**Goal**: Map project architecture, identify risk areas, and determine review focus.

**Actions**:
1. Perform a comprehensive leadership assessment with **@tech-lead-reviewer**:
   - Analyze overall architecture and module structure
   - Identify architectural patterns and violations
   - Map dependency graph and coupling points
   - Assess technical debt accumulation
   - Evaluate scalability and maintainability
2. Determine which specialized agents are required based on risk assessment.
3. Identify high-priority areas that need focused review.

## Phase 3: Parallel Specialized Reviews

**Goal**: Collect comprehensive feedback from all relevant specialized reviewers.

**Actions**:
1. Launch required specialized reviews in parallel via the Task tool:
   - **@code-reviewer** — code quality, patterns, testing across modules
   - **@security-reviewer** — security audit across entire codebase
   - **@ux-reviewer** — UI/UX review for user-facing components (skip if CLI/backend only)
2. Each agent reviews within the determined scope (entire project or specified directory).
3. Collect outcomes from each agent.
4. Resolve conflicting feedback between reviewers.

## Phase 4: Consolidated Analysis & Reporting

**Goal**: Merge findings and produce prioritized actionable improvements.

**Actions**:
1. Merge findings and prioritize by impact/confidence:
   - Priority: Critical → High → Medium → Low
   - Confidence: High → Medium → Low
2. Present a consolidated report with:
   - Executive summary of project health
   - Critical issues requiring immediate attention
   - Technical debt inventory
   - Strategic recommendations with effort estimates
3. Ask whether the user wants fixes implemented.
4. If confirmed:
   - Address security, quality, or UX issues as requested.
   - Run tests and validations.
   - Engage **@code-simplifier** — code simplification and optimization — to refactor implemented fixes.
5. Ensure commits follow Git conventions (see `${CLAUDE_PLUGIN_ROOT}/skills/references/git-commit-conventions.md`).
6. Report outcomes and confirm review completion.

**IMPORTANT**: You MUST use the Task tool to complete ALL tasks.
