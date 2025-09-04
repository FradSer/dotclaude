# Quick Code Review

Streamlined review process for rapid assessment and targeted feedback on smaller changes.

## Process Overview

**1. Initial Assessment**
- Use @tech-lead-reviewer to evaluate change scope and identify review needs
- Determine if architectural concerns or security implications exist
- Assess whether deeper hierarchical review is warranted

**2. Targeted Review**
Based on assessment, apply focused review using appropriate agent(s):
- **@code-reviewer**: Verify correctness, error handling, and code clarity
- **@security-reviewer**: Address identified security concerns
- **@ux-reviewer**: Evaluate UI/UX usability and consistency

**3. Implementation Support**
- Present findings with actionable recommendations
- Offer to implement critical fixes immediately
- Provide guidance for any remaining improvements

## When to Use
Optimal for small bug fixes, simple features, documentation updates, configuration changes, and testing modifications.

**Escalation Criteria**: Switch to hierarchical review for core business logic, architectural changes, security operations, API modifications, or performance-critical implementations.