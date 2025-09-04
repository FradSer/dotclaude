# Hierarchical Code Review

Comprehensive multi-stage review using specialized subagents for architectural assessment, parallel specialized analysis, and consolidated recommendations.

## Process Overview

**1. Technical Leadership Assessment**
- Use @tech-lead-reviewer to evaluate architectural impact, technical debt, and identify critical risk areas
- Focus on system-wide implications, scalability, and maintainability
- Determine which specialized reviews are needed

**2. Specialized Parallel Reviews** 
Based on tech lead assessment, conduct applicable reviews:
- **@code-reviewer**: Analyze correctness, logic, error handling, and test coverage
- **@security-reviewer**: Examine authentication, data protection, input validation, and dependencies
- **@ux-reviewer**: Assess usability, accessibility, and design consistency (when applicable)

**3. Consolidated Analysis**
- Use @code-simplifier to integrate findings and provide prioritized recommendations
- Resolve conflicts between different review perspectives
- Create actionable improvement suggestions

**4. Implementation Planning**
- Present consolidated findings to user
- Offer to implement high-priority fixes immediately
- Provide guidance for addressing remaining issues

## When to Use
Ideal for major features, architectural changes, critical business logic, cross-team projects, and technology upgrades requiring comprehensive oversight.