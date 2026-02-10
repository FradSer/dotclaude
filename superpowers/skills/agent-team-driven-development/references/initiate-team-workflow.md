# Workflow: Initiate Team

## Steps

### 1. Identify the Need
- **Complex Plan?** -> Spawn an **Architect** to break it down.
- **Parallel Tasks?** -> Spawn multiple **Implementers**.
- **Quality Control?** -> Spawn a **Reviewer**.
- **Research?** -> Spawn **Researchers** with competing hypotheses.

### 2. Spawn the Team
You can start a team in two ways:

**Option A: Explicit Request**
Use natural language to describe the team and their specific context.
```
Create an agent team to refactor the auth module.
- 1 Architect to design the new schema.
- 2 Implementers to migrate the user and session services.
- 1 Reviewer to check security.
```

**Option B: Auto-Proposal**
For complex requests, Claude may propose creating a team. Review the proposed structure and confirm if it looks correct.

### 3. Set Context (Crucial)
Teammates start with a fresh context (except for `CLAUDE.md`, skills, and MCPs). They **do not** see your previous conversation history.

**Must-haves in the spawn prompt:**
- Specific files to focus on.
- The goal of the task.
- Constraints (e.g., "Use TDD", "Follow existing patterns").

*Example:*
> "Spawn a reviewer to check `src/auth/` for JWT vulnerabilities. Read `CLAUDE.md` first to understand project standards."