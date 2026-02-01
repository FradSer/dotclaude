# Failure Resolution Process

When quality checks fail, follow this systematic process:

## 1. Task List Creation

Use TodoWrite to create specific task list for failures:
- List each failing check as a separate task
- Include error messages and context
- Prioritize critical failures first

## 2. Agent Collaboration

Use Task tool with specialized agents to resolve issues:

- **@code-reviewer** — For logic correctness, tests, and error handling
  - Use when tests fail or code logic is incorrect
  - Request code review and suggestions for fixes

- **@security-reviewer** — For authentication, data protection, and validation
  - Use when security scans fail
  - Request security review and remediation steps

## 3. Systematic Resolution

Fix issues one at a time:
1. Address the issue following agent recommendations
2. Run validation after each fix
3. Mark task completed immediately after resolution
4. Move to next failure

## 4. Re-run Quality Checks

After all fixes:
- Re-run all quality checks until all pass
- Ensure no new issues were introduced
- Validate commit messages follow standards

## 5. Document Changes

Document all fixes made:
- Add comments explaining why fixes were needed
- Update PR description with resolution details
- Reference any agents or tools used in resolution
