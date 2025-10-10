---
allowed-tools: Task
argument-hint: [files-or-directories]
description: Comprehensive multi-stage code review using specialized subagents
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --porcelain`
- Base branch: !`(git show-branch | grep '*' | grep -v "$(git rev-parse --abbrev-ref HEAD)" | head -1 | sed 's/.*\[\([^]]*\)\].*/\1/' | sed 's/\^.*//' 2>/dev/null) || echo "develop"`
- Changes since base: !`BASE=$(git merge-base HEAD develop 2>/dev/null || git merge-base HEAD main 2>/dev/null) && git log --oneline $BASE..HEAD`
- Files changed since base: !`BASE=$(git merge-base HEAD develop 2>/dev/null || git merge-base HEAD main 2>/dev/null) && git diff --name-only $BASE..HEAD`
- Test commands available: !`([ -f package.json ] && echo "npm/pnpm/yarn test") || ([ -f Cargo.toml ] && echo "cargo test") || ([ -f pyproject.toml ] && echo "pytest/uv run pytest") || ([ -f go.mod ] && echo "go test") || echo "no standard test framework detected"`

## Your task

Perform comprehensive hierarchical code review on: $ARGUMENTS

**Multi-stage review process:**

**1. Technical Leadership Assessment**
- Use @tech-lead-reviewer sub agent to evaluate architectural impact, technical debt, and identify critical risk areas
- Focus on system-wide implications, scalability, and maintainability
- Determine which specialized reviews are needed

**2. Comprehensive Parallel Reviews**
Use Task tool to launch ALL applicable specialized reviews in parallel:
- **code-reviewer**: Always analyze correctness, logic, error handling, and test coverage
- **security-reviewer**: Always examine authentication, data protection, input validation, and dependencies
- **ux-reviewer**: Always assess usability, accessibility, and design consistency (skip only if purely backend/CLI code)

**3. Consolidated Analysis**
- Integrate findings from all reviews and provide recommendations by:
  - **Priority Level**: Critical → High → Medium → Low
  - **Confidence Level**: High (90%+) → Medium (70-89%) → Low (<70%)
- Resolve conflicts between different review perspectives
- Create actionable improvement suggestions ranked by impact

**4. Results Presentation**
- Present findings organized by priority and confidence matrix
- Provide clear rationale for each recommendation
- Ask user: "Would you like me to implement any of these fixes?"

**5. Optional Implementation** (if user confirms)
Based on issue type, apply targeted fixes:
- **Security issues**: Address vulnerabilities, input validation, authentication flows
- **Code quality**: Fix naming, algorithms, error handling, test coverage
- **UI/UX issues**: Improve usability, accessibility, design consistency

**6. Final Optimization**
- Use Task tool with code-simplifier to review and optimize implemented fixes:
  - Eliminate any redundancy introduced during fixes
  - Reduce complexity where possible
  - Apply modern syntax and idiomatic patterns
  - Ensure SOLID principles are maintained
- Run tests and validation after optimization
- Git commit atomic changes conventional:
  - Commit message title must be entirely lowercase
  - Title must be less than 50 characters
  - Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
  - Use atomic commits for logical units of work
- Push changes to remote
