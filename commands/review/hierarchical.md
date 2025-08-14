# Hierarchical Code Review

Multi-stage comprehensive review using multiple subagents: strategic assessment, parallel specialized reviews, then consolidated recommendations.

**Stage 1**: Use @tech-lead-reviewer to think hard and assess architectural impact, technical debt, and identify risk areas (security, performance, complexity). Guide specialized review focus.

**Stage 2**: Parallel reviews using applicable subagents:

* @code-reviewer: business logic, error handling, test coverage
* @security-reviewer: authentication, data protection, input validation, dependencies
* @ux-reviewer (if applicable): usability, accessibility, consistency

**Stage 3**: Use @code-simplifier to think hard and consolidate all findings into prioritized improvement roadmap, resolving conflicts and integrating recommendations.

**Stage 4**: Ask user if they want to proceed with implementing any fixes based on the review findings.

For major features, architectural refactoring, critical business logic, cross-team projects, and technology upgrades.