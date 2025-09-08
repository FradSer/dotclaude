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
- Use @code-simplifier to integrate findings and provide recommendations by:
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
- Use @code-simplifier to review and optimize implemented fixes:
  - Eliminate any redundancy introduced during fixes
  - Reduce complexity where possible
  - Apply modern syntax and idiomatic patterns
  - Ensure SOLID principles are maintained
- Run tests and validation after optimization
- Commit changes following @commands/git/commit-and-push.md requirements:
  - Commit message title must be entirely lowercase
  - Title must be less than 50 characters
  - Follow conventional commits format (feat:, fix:, chore:, etc.)
  - Use atomic commits for logical units of work
- Push changes to remote