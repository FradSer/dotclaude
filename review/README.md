# Review Plugin

Multi-agent review system for enforcing high code quality.

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

**Focus areas:**
- Correctness and logic analysis
- Standards compliance (CLAUDE.md)
- Maintainability and readability
- Error handling and edge cases
- Code structure and organization
- Performance and efficiency
- Testing and quality assurance
- Security considerations

**When triggered:**
- Automatically in `/hierarchical` review
- Can be invoked manually when reviewing code

---

### `security-reviewer`

Security specialist auditing authentication, data protection, and inputs.

**Metadata:**

| Field | Value |
|-------|-------|
| Model | `sonnet` |
| Color | `green` |

**Focus areas:**
- Common vulnerabilities (SQL Injection, XSS, CSRF, SSRF, XXE)
- Authentication and authorization
- Input validation and data handling
- Cryptography and data protection
- Error handling and information disclosure
- Dependency and configuration security

**When triggered:**
- Automatically in `/hierarchical` review
- Can be invoked manually for security audits

**Output structure:**
1. CRITICAL VULNERABILITIES (immediate security risks)
2. HIGH PRIORITY ISSUES (significant security concerns)
3. MEDIUM PRIORITY ISSUES (potential security weaknesses)
4. BEST PRACTICE RECOMMENDATIONS (security improvements)
5. COMPLIANCE NOTES (OWASP, PCI-DSS, GDPR)

---

### `tech-lead-reviewer`

Architectural reviewer focused on system-wide impact and risk.

**Metadata:**

| Field | Value |
|-------|-------|
| Model | `sonnet` |
| Color | `magenta` |

**Focus areas:**
- Architectural integrity and Clean Architecture adherence
- Domain boundaries and module responsibilities
- Performance implications and scalability
- Operational readiness (logging, metrics, rollout safety)
- Risk assessment and mitigation strategies

**Working process:**
1. Map the change onto existing architecture
2. Identify coupling points that may become maintenance liabilities
3. Flag design decisions that violate guardrails or introduce hidden costs
4. Recommend strategic improvements with rationale and estimated effort

**When triggered:**
- Automatically in `/hierarchical` review
- Can be invoked manually for architecture review

---

### `ux-reviewer`

Experience specialist focused on usability and accessibility.

**Metadata:**

| Field | Value |
|-------|-------|
| Model | `sonnet` |
| Color | `yellow` |

**Focus areas:**
- Information hierarchy, layout clarity, and visual rhythm
- Interaction patterns, state management, and feedback mechanisms
- Accessibility compliance (WCAG AA): semantics, keyboard flows, contrast
- Copywriting tone, localization readiness, and content density
- Performance considerations affecting perceived responsiveness

**Process:**
1. Review component structure and states (loading, empty, error, success)
2. Assess controls for discoverability and affordance
3. Validate color and typography against design tokens
4. Recommend usability tests or analytics to validate assumptions

**When triggered:**
- Automatically in `/hierarchical` review (if UI changes detected)
- Can be invoked manually for UX review

## User-Invocable Skills

### `/quick`

Streamlined code review for rapid assessment and targeted feedback.

**Metadata:**

| Field | Value |
|-------|-------|
| Allowed Tools | `Task` |
| Argument Hint | `[files-or-directories]` |

**What it does:**
1. Runs initial assessment with **@tech-lead-reviewer** to gauge risk
2. Triggers relevant specialized reviews selectively:
   - **@code-reviewer** — logic correctness, tests, error handling
   - **@security-reviewer** — authentication, data protection, validation
   - **@ux-reviewer** — usability and accessibility (skip if purely backend/CLI)
3. Summarizes results by priority (Critical → High → Medium → Low)
4. Offers optional implementation support with **@code-simplifier**
5. Ensures resulting commits follow conventional standards

**Usage:**
```bash
/quick
```

Or with specific files:
```bash
/quick src/auth/login.ts
```

**Features:**
- Fast, focused review
- Targets only changed files
- Selective agent execution (minimizes turnaround time)
- Quick feedback cycle
- Identifies critical issues
- Suitable for rapid iterations

---

### `/hierarchical`

Comprehensive multi-stage code review using all specialized subagents.

**Metadata:**

| Field | Value |
|-------|-------|
| Allowed Tools | `Task` |
| Argument Hint | `[files-or-directories]` |

**What it does:**
1. Performs leadership assessment with **@tech-lead-reviewer** to map risk areas
2. Launches specialized reviews in parallel:
   - **@code-reviewer** — logic correctness, tests, error handling
   - **@security-reviewer** — authentication, data protection, validation
   - **@ux-reviewer** — usability and accessibility (skip if purely backend/CLI)
3. Consolidates findings by priority and confidence
4. Offers optional implementation support
5. Engages **@code-simplifier** for final optimization

**Usage:**
```bash
/hierarchical
```

**Features:**
- Comprehensive multi-agent review
- Parallel agent execution
- Consolidated findings
- Prioritized issue reporting
- Thorough quality assessment
- Final optimization pass

**Review report includes:**
- Critical issues (must fix)
- Important issues (should fix)
- Suggestions (nice to have)
- Agent-specific findings
- File-specific recommendations

## Installation

```bash
claude plugin install review@frad-dotclaude
```

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

## Version

1.0.0
