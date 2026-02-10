---
name: agent-team-driven-development
description: This skill provides guidance on choosing between Agent Teams and Sub-agents, and on using Agent Teams to execute complex implementation plans by coordinating specialized teammates in parallel.
user-invocable: false
version: 2.3.0
---

# Agent Team Driven Development for Plan Execution

Coordinate multiple specialized teammates working in parallel to execute complex implementation plans.

## Agent Teams vs Sub-agents

Choose based on whether workers need to communicate with each other.

| Dimension | Sub-agents | Agent Teams |
|---|---|---|
| **Communication** | Results return to caller only | Teammates message each other directly |
| **Coordination** | Main agent manages all work | Shared task list with self-coordination |
| **Best for** | Focused tasks where only the result matters | Complex work requiring discussion and collaboration |
| **Token cost** | Lower | Higher: each teammate is a separate instance |

Use **Sub-agents** for independent tasks needing no inter-worker communication (research, validation, file search). Use **Agent Teams** when teammates must share findings, challenge each other, or self-coordinate across 3+ parallel work streams. For sequential or highly interdependent tasks, use a single session.

## Execution Workflow

1. **Analyze plan** -- identify task independence, file conflicts, and required roles (Implementer, Reviewer, Architect)
2. **Spawn team** -- provide each teammate with task assignments, file paths, constraints, and verification criteria. Teammates do **not** inherit conversation history.
3. **Coordinate** -- monitor via shared task list, facilitate cross-teammate communication, use delegate mode (`Shift+Tab`) to keep the lead focused on coordination
4. **Verify and clean up** -- validate integration, run tests, shut down teammates, clean up team resources via the lead

See `./references/initiate-team-workflow.md` and `./references/manage-team-workflow.md` for detailed workflows.

## Roles

- **Implementer**: executes coding tasks on assigned files, follows TDD/BDD. See `./references/implementer-role.md`.
- **Reviewer**: validates quality, security, and plan compliance. See `./references/reviewer-role.md`.
- **Architect**: resolves cross-cutting concerns, maintains system-wide consistency. See `./references/architect-role.md`.

## Key Practices

- Assign distinct file ownership per teammate to prevent edit conflicts
- Include 5-6 tasks per teammate for steady throughput
- Document task dependencies explicitly so blocked tasks wait automatically
- Provide full context in spawn prompts (file paths, goals, constraints)
- Require verification evidence (test results, etc.) upon task completion
- Monitor frequently; unattended teams risk wasted effort

For architecture, capabilities, and limitations, see `./references/official-documentation.md`.