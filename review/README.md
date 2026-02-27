# Review Plugin

Multi-agent review system for enforcing high code quality.

**Version**: 0.4.0

## Installation

```bash
claude plugin install review@frad-dotclaude
```

## Overview

The Review Plugin provides a comprehensive code review system with multiple specialized agents. Each agent focuses on different aspects of code quality, providing thorough and actionable feedback.

## Agents

### `code-reviewer`

Expert reviewer focusing on correctness, standards, and maintainability.

**Metadata:**

| Field | Value |
|-------|-------|
| Model | `sonnet` |
| Color | `blue` |
| Tools | `Read`, `Glob`, `Grep`, `Bash(git:*)` |

**Workflow:** Context Gathering -> Systematic Review -> Synthesize Findings

**Focus areas:**
- Correctness and logic analysis (race conditions, null safety, async patterns)
- Standards compliance (CLAUDE.md, language conventions, SOLID/DRY/KISS)
- Maintainability (naming, complexity, separation of concerns)
- Performance (N+1 queries, memory leaks, algorithm complexity)
- Testing (coverage, edge cases, isolation, assertions)

**Output:** Structured markdown with Critical Issues, Important Issues, Suggestions, and Positive sections

**When triggered:**
- Automatically in `/quick` and `/hierarchical` reviews
- Can be invoked manually for code quality assessment

---

### `security-reviewer`

Security specialist auditing authentication, data protection, and inputs.

**Metadata:**

| Field | Value |
|-------|-------|
| Model | `sonnet` |
| Color | `green` |
| Tools | `Read`, `Glob`, `Grep`, `Bash(git:*)` |

**Workflow:** Attack Surface Mapping -> Vulnerability Scanning -> Risk Assessment

**Focus areas:**
- OWASP Top 10 2026 vulnerabilities
- Authentication & authorization (session management, JWT, MFA)
- Input validation & data handling
- Cryptography (AES-256, RSA-2048+, bcrypt)
- Configuration security (dependencies, secrets management)

**Output:** Structured markdown with risk level, attack scenarios, remediation steps, and compliance notes (OWASP/PCI-DSS/GDPR)

**When triggered:**
- Automatically in `/quick` and `/hierarchical` reviews
- Can be invoked manually for security audits

---

### `tech-lead-reviewer`

Architectural reviewer focused on system-wide impact and risk.

**Metadata:**

| Field | Value |
|-------|-------|
| Model | `sonnet` |
| Color | `magenta` |
| Tools | `Read`, `Glob`, `Grep`, `Bash(git:*)` |

**Workflow:** Architecture Mapping -> Impact Assessment -> Recommendations

**Focus areas:**
- Architectural integrity (Clean Architecture, dependency rule)
- Scalability (performance ceilings, bottlenecks, resource implications)
- Operational readiness (logging, metrics, rollout safety, rollback capability)
- Technical debt identification and tracking
- Strategic recommendations with effort estimates

**Output:** Structured markdown with impact matrix, blockers, technical debt items, and prioritized recommendations

**When triggered:**
- First agent in `/quick` review (initial assessment)
- First agent in `/hierarchical` review
- Can be invoked manually for architecture review

---

### `ux-reviewer`

Experience specialist focused on usability and accessibility.

**Metadata:**

| Field | Value |
|-------|-------|
| Model | `sonnet` |
| Color | `yellow` |
| Tools | `Read`, `Glob`, `Grep`, `Bash(git:*)` |

**Workflow:** Component Analysis -> Heuristic Evaluation -> Accessibility Audit

**Focus areas:**
- Usability (Nielsen's 10 heuristics, interaction patterns)
- Accessibility (WCAG 2.2 AA compliance checklist)
- Component states (loading, empty, error, success)
- Design consistency (tokens, typography, spacing)
- Perceived performance (skeleton states, optimistic updates)

**Output:** Structured markdown with accessibility issues (WCAG-tagged), usability findings, missing states, and analytics recommendations

**When triggered:**
- Automatically in `/quick` and `/hierarchical` reviews (if UI changes detected)
- Can be invoked manually for UX/accessibility review

## User-Invocable Skills

### `/quick`

Streamlined code review for rapid assessment and targeted feedback.

**Metadata:**

| Field | Value |
|-------|-------|
| Allowed Tools | `Task` |
| Argument Hint | `[files-or-directories]` |

**Review scope** (checked in order):
1. Uncommitted changes (if git is not clean)
2. Files modified during current session
3. User-specified files/directories via argument
4. Prompt user to specify scope if none of the above

**What it does:**
1. Determine review scope automatically or from argument
2. Run initial assessment with **@tech-lead-reviewer** to gauge risk
3. Triggers relevant specialized reviews selectively:
   - **@code-reviewer** — logic correctness, tests, error handling
   - **@security-reviewer** — authentication, data protection, validation
   - **@ux-reviewer** — usability and accessibility (skip if purely backend/CLI)
4. Summarizes results by priority (Critical → High → Medium → Low)
5. Offers optional implementation support with **@code-simplifier**
6. Ensures resulting commits follow conventional standards

**Usage:**
```bash
/quick                           # Auto-detect scope from git/session
/quick src/auth/login.ts         # Review specific files
/quick src/components/           # Review directory
```

**Features:**
- Smart scope detection
- Fast, focused review
- Selective agent execution
- Quick feedback cycle
- Suitable for rapid iterations

---

### `/hierarchical`

Comprehensive project-level review using all specialized subagents.

**Metadata:**

| Field | Value |
|-------|-------|
| Allowed Tools | `Task` |
| Argument Hint | `[directory]` |

**Review scope:**
- Reviews entire project or specified directory
- Provides full codebase analysis (not just changes)

**What it does:**
1. Determine project scope (current directory or user-specified)
2. Perform comprehensive leadership assessment with **@tech-lead-reviewer**:
   - Analyze overall architecture and module structure
   - Map dependency graph and coupling points
   - Assess technical debt and scalability
3. Launches specialized reviews in parallel:
   - **@code-reviewer** — code quality across modules
   - **@security-reviewer** — security audit across codebase
   - **@ux-reviewer** — UI/UX review for user-facing components
4. Consolidates findings with executive summary
5. Provides technical debt inventory and strategic recommendations
6. Offers optional implementation support

**Usage:**
```bash
/hierarchical                    # Review entire project
/hierarchical src/               # Review specific directory
```

**Features:**
- Project-level comprehensive review
- Architecture analysis
- Security audit
- Technical debt inventory
- Strategic recommendations with effort estimates
- Parallel agent execution

**Review report includes:**
- Critical issues (must fix)
- Important issues (should fix)
- Suggestions (nice to have)
- Agent-specific findings
- File-specific recommendations

## Best Practices

### Using `/quick`
- Use for rapid feedback during development
- Run after small changes
- Great for iterative development
- Use before committing changes
- Fast turnaround for quick fixes

### Using `/hierarchical`
- Use before creating PRs
- Run on feature branches before merging
- Use for comprehensive quality assessment
- Great for identifying complex issues
- Use when quality is critical

### Agent Selection
- Use `code-reviewer` for general code quality
- Use `security-reviewer` for security-critical code
- Use `tech-lead-reviewer` for architectural decisions
- Use `ux-reviewer` for UI/UX changes
- Use all agents via `/hierarchical` for comprehensive review

## Workflow Integration

### Quick Review Workflow:
```bash
# Make changes
/quick
# Fix issues
/quick
# Commit when satisfied
```

### Comprehensive Review Workflow:
```bash
# Complete feature
/hierarchical
# Fix all critical issues
# Re-run review if needed
# Create PR when clean
```

### Agent-Specific Review:
```bash
# For security-critical code
@security-reviewer Review this authentication code

# For architecture decisions
@tech-lead-reviewer Review this module design

# For UI changes
@ux-reviewer Review this login page
```

## Requirements

- Git repository
- Base branch (develop or main) for comparison
- Project with codebase to review

## Troubleshooting

### Review takes too long

**Issue**: Hierarchical review is slow

**Solution**:
- This is normal for large changes
- Agents run in parallel when possible
- Use `/quick` for faster feedback
- Review specific files instead of all changes

### Too many issues reported

**Issue**: Review finds too many issues

**Solution**:
- Focus on critical issues first
- Address important issues incrementally
- Some issues may be false positives - review carefully
- Use `/quick` for focused feedback

### Agent not finding issues

**Issue**: Agent misses obvious problems

**Solution**:
- Provide more context in code
- Check if agent is appropriate for the code type
- Try different agent for different perspective
- Use multiple agents via `/hierarchical`

## Tips

- **Use quick reviews frequently**: Catch issues early in development
- **Use hierarchical for PRs**: Comprehensive review before merging
- **Review agent findings**: Each agent provides valuable insights
- **Fix critical issues first**: Prioritize by severity
- **Iterate on reviews**: Re-run review after fixes

## Author

Frad LEE (fradser@gmail.com)

## License

MIT
