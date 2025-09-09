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

**3. Results Analysis**
- Present findings organized by:
  - **Priority**: Critical → High → Medium → Low
  - **Confidence**: High (90%+) → Medium (70-89%) → Low (<70%)
- Provide actionable recommendations with clear rationale
- Ask user: "Would you like me to implement any of these fixes?"

**4. Optional Implementation** (if user confirms)
Apply targeted fixes based on identified issues:
- **Security fixes**: Address vulnerabilities and validation issues
- **Code quality**: Improve naming, logic, error handling
- **UI/UX improvements**: Enhance usability and accessibility

**5. Final Optimization**
- Use @code-simplifier to optimize implemented fixes:
  - Remove any redundancy introduced during fixes
  - Simplify complex logic where appropriate
  - Apply modern language features and patterns
  - Maintain code clarity and readability
- Run tests and Git commit atomic changes conventional:- Run tests and commit changes with proper formatting:
  - Commit message title must be entirely lowercase
  - Title must be less than 50 characters
  - Follow conventional commits format (feat:, fix:, chore:, etc.)
  - Use atomic commits for logical units of work
- Push changes to remote
