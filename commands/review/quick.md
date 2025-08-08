# Quick Code Review

Simple two-stage review for rapid assessment and focused feedback.

**Stage 1**: Use @tech-lead-reviewer to assess whether the change needs deeper review, has architectural concerns, or security implications.

**Stage 2**: Based on findings, choose one or multiple agents for parallel review:
* @code-reviewer: for correctness, error handling, naming clarity
* @security-reviewer: if security concerns identified
* @ux-reviewer: for UI/UX usability issues

For small bug fixes, simple features, formatting, documentation, tests, and configuration changes. Escalate to hierarchical review for core business logic, architectural impact, security operations, API changes, or performance-critical paths.