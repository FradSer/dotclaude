# Failure Resolution Process

When quality checks fail, follow this systematic process:

## 1. Track the Failures

Track each failing check as a task (TaskCreate/TaskUpdate, or an inline checklist in your message):
- List each failing check as a separate task
- Include error messages and context
- Prioritize critical failures first

## 2. Systematic Resolution

Fix issues one at a time:
1. Address the issue
2. Run validation after each fix
3. Mark task completed immediately after resolution
4. Move to next failure

## 3. Re-run Quality Checks

After all fixes:
- Re-run all quality checks until all pass
- Ensure no new issues were introduced
- Validate commit messages follow standards

## 4. Document Changes

Document all fixes made:
- Add comments explaining why fixes were needed
- Update PR description with resolution details
