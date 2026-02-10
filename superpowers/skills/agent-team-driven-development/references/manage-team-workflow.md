# Workflow: Manage Team

## Task Management

The Team Lead (you) orchestrates the work using the **Task List**.

- **Assign Tasks**: explicitly tell the lead: "Assign the API task to the backend teammate".
- **Self-Claiming**: Teammates can autonomously claim unassigned tasks if they are unblocked.
- **Dependencies**: Tasks can depend on others. Teammates wait for dependencies to clear.

## Communication

- **Direct Message**: Talk to a specific teammate.
  - *In-process*: Use `Shift+Up/Down` to select, then type.
  - *Split-pane*: Click the pane and type.
- **Broadcast**: Send a message to all teammates (use sparingly).
- **Interruption**: If a teammate is going off-track, interrupt them (Ctrl+C in their pane/view).

## Modes

- **Delegate Mode**: Press `Shift+Tab` to toggle. Restricts the lead to coordination tools only (spawning, messaging, tasks), preventing it from doing implementation work itself.
- **Plan Mode**: You can require teammates to submit a plan for approval before implementing.
  - *Command*: "Require plan approval for the Architect."

## Monitoring & Review

1.  **Monitor**: Watch teammate output in real-time.
2.  **Review**: When a teammate reports completion, verify their work.
    - "Reviewer, check Implementer 1's work on task 3."
    - Or run `git diff` and tests yourself.
3.  **Feedback**: Provide specific feedback to the teammate if changes are needed.

## Cleanup

When the goal is achieved:

1.  **Shutdown**: "Ask the team to shut down" or "Clean up the team".
2.  **Verify**: Ensure no orphaned processes (tmux sessions) remain.