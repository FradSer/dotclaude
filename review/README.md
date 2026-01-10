# Review Plugin

Multi-agent review system for enforcing high code quality.

## Overview

The Review Plugin provides a comprehensive code review system with multiple specialized agents. Each agent focuses on different aspects of code quality, providing thorough and actionable feedback.

## Agents

### `code-reviewer`

Expert reviewer focusing on correctness, standards, and maintainability.

**Focus areas:**
- Correctness and logic analysis
- Standards compliance (CLAUDE.md)
- Maintainability and readability
- Error handling and edge cases
- Code structure and organization

**When triggered:**
- Automatically in `/hierarchical` review
- Can be invoked manually when reviewing code

**Model:** Sonnet

**Color:** Blue

### `security-reviewer`

Security-focused code review agent.

**Focus areas:**
- Security vulnerabilities
- Input validation and sanitization
- Authentication and authorization
- Data protection and privacy
- Security best practices

**When triggered:**
- Automatically in `/hierarchical` review
- Can be invoked manually for security audits

**Model:** Sonnet

**Color:** Red

### `tech-lead-reviewer`

Architecture and design review agent.

**Focus areas:**
- Architecture decisions
- Design patterns and abstractions
- Scalability and performance
- Code organization and structure
- Technical debt

**When triggered:**
- Automatically in `/hierarchical` review
- Can be invoked manually for architecture review

**Model:** Sonnet

**Color:** Purple

### `ux-reviewer`

User experience and UI review agent.

**Focus areas:**
- User interface design
- User experience flows
- Accessibility and usability
- UI/UX best practices
- Interaction patterns

**When triggered:**
- Automatically in `/hierarchical` review
- Can be invoked manually for UX review

**Model:** Sonnet

**Color:** Green

## Commands

### `/quick`

Streamlined code review for rapid assessment and targeted feedback.

**What it does:**
1. Analyzes current branch changes
2. Identifies files changed since base branch
3. Performs focused review on changed files
4. Provides targeted feedback quickly
5. Highlights critical issues and improvements

**Usage:**
```bash
/quick
```

Or with specific files:
```bash
/quick src/auth/login.ts
```

**Example workflow:**
```bash
# Make some changes
# Then run quick review
/quick

# Claude will:
# - Analyze changed files
# - Provide focused feedback
# - Highlight critical issues
# - Suggest improvements
```

**Features:**
- Fast, focused review
- Targets only changed files
- Quick feedback cycle
- Identifies critical issues
- Suitable for rapid iterations

### `/hierarchical`

Comprehensive hierarchical review using all specialized agents.

**What it does:**
1. Analyzes current branch changes
2. Launches all 4 specialized agents in parallel:
   - `code-reviewer` - Correctness and standards
   - `security-reviewer` - Security vulnerabilities
   - `tech-lead-reviewer` - Architecture and design
   - `ux-reviewer` - User experience (if UI changes)
3. Consolidates findings from all agents
4. Prioritizes issues by severity
5. Provides comprehensive review report

**Usage:**
```bash
/hierarchical
```

**Example workflow:**
```bash
# Before creating PR, run comprehensive review
/hierarchical

# Claude will:
# - Launch all review agents
# - Consolidate findings
# - Prioritize issues
# - Provide comprehensive report
```

**Features:**
- Comprehensive multi-agent review
- Parallel agent execution
- Consolidated findings
- Prioritized issue reporting
- Thorough quality assessment

**Review report includes:**
- Critical issues (must fix)
- Important issues (should fix)
- Suggestions (nice to have)
- Agent-specific findings
- File-specific recommendations

## Installation

This plugin is included in the Claude Code repository. The commands and agents are automatically available when using Claude Code.

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
