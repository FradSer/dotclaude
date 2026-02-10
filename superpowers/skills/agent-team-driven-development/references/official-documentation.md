# Agent Teams: Architecture, Capabilities, and Limitations

Reference material adapted from the official Claude Code documentation. Covers the technical details that complement the main skill and workflow references.

## Architecture

An agent team consists of four components:

| Component | Role |
|---|---|
| **Team lead** | The main Claude Code session that creates the team, spawns teammates, and coordinates work |
| **Teammates** | Separate Claude Code instances that each work on assigned tasks |
| **Task list** | Shared list of work items that teammates claim and complete |
| **Mailbox** | Messaging system for communication between agents |

Teams and tasks are stored locally:
- Team config: `~/.claude/teams/{team-name}/config.json`
- Task list: `~/.claude/tasks/{team-name}/`

The team config contains a `members` array with each teammate's name, agent ID, and agent type. Teammates can read this file to discover other team members.

## Starting a Team

Two entry points:
- **Explicit request**: describe the team structure and task in natural language
- **Auto-proposal**: Claude may suggest creating a team for complex tasks; confirm before it proceeds

Claude never creates a team without user approval.

## Display Modes

| Mode | How it works | Requirements |
|---|---|---|
| **In-process** (default) | All teammates run in the main terminal. `Shift+Up/Down` to select, type to message. | Any terminal |
| **Split panes** | Each teammate gets its own pane. Click into a pane to interact. | tmux or iTerm2 with `it2` CLI |

Configure via `"teammateMode"` in `settings.json` (`"in-process"`, `"tmux"`, or `"auto"`) or CLI flag `--teammate-mode`.

## Key Capabilities

### Delegate Mode
Press `Shift+Tab` to toggle. Restricts the lead to coordination-only tools (spawning, messaging, shutting down, task management). Prevents the lead from implementing tasks itself.

### Plan Approval
Require teammates to plan before implementing. The teammate works in read-only plan mode until the lead approves. Rejected plans get feedback and the teammate revises.

Example: "Spawn an architect teammate. Require plan approval before they make any changes."

### Direct Teammate Communication
Each teammate is a full Claude Code session. Message any teammate directly:
- In-process: `Shift+Up/Down` to select, type to send. `Enter` to view session, `Escape` to interrupt. `Ctrl+T` to toggle task list.
- Split panes: click into the pane.

### Task Management
The shared task list has three states: pending, in progress, completed. Tasks can depend on other tasks -- blocked tasks unblock automatically when dependencies complete. Task claiming uses file locking to prevent race conditions.

Assignment modes:
- **Lead assigns**: tell the lead which task to give to which teammate
- **Self-claim**: teammates pick up the next unassigned, unblocked task automatically

### Teammate Messaging
- **message**: send to one specific teammate
- **broadcast**: send to all teammates (use sparingly -- costs scale with team size)

### Quality Gates via Hooks
- **TeammateIdle**: runs when a teammate is about to go idle. Exit code 2 sends feedback and keeps the teammate working.
- **TaskCompleted**: runs when a task is being marked complete. Exit code 2 prevents completion and sends feedback.

## Context and Permissions

- Each teammate has its own context window
- Teammates load project context automatically (`CLAUDE.md`, MCP servers, skills) but do **not** inherit the lead's conversation history
- Provide task-specific details in the spawn prompt
- All teammates start with the lead's permission settings; individual modes can be changed after spawning

## Token Usage

Agent teams use significantly more tokens than a single session. Each teammate is a separate Claude instance with its own context window. Token usage scales linearly with the number of active teammates.

Worth the cost for: research, review, new feature work with parallel streams.
Not worth it for: routine tasks, sequential work, single-file changes.

## Limitations

Current known limitations (agent teams are experimental):

- **No session resumption**: `/resume` and `/rewind` do not restore in-process teammates. After resuming, tell the lead to spawn new teammates.
- **Task status can lag**: teammates sometimes fail to mark tasks completed, blocking dependents. Check manually and nudge if stuck.
- **Shutdown can be slow**: teammates finish their current tool call before shutting down.
- **One team per session**: clean up the current team before starting a new one.
- **No nested teams**: teammates cannot spawn their own teams. Only the lead manages the team.
- **Lead is fixed**: the creating session is lead for the team's lifetime. No leadership transfer.
- **Permissions set at spawn**: all teammates inherit the lead's mode. Per-teammate modes at spawn time are not supported.
- **Split panes require tmux or iTerm2**: not supported in VS Code integrated terminal, Windows Terminal, or Ghostty.

## Troubleshooting

| Problem | Solution |
|---|---|
| Teammates not appearing | In-process mode: press `Shift+Down` to cycle. Also verify the task warranted a team. For split panes: check `which tmux`. |
| Too many permission prompts | Pre-approve common operations in permission settings before spawning. |
| Teammates stopping on errors | Check output via `Shift+Up/Down` or pane click. Give additional instructions or spawn a replacement. |
| Lead shuts down early | Tell the lead to wait for teammates to finish before proceeding. |
| Orphaned tmux sessions | Run `tmux ls` and `tmux kill-session -t <session-name>`. |

## Cleanup

Always use the lead to clean up (`"Clean up the team"`). The lead checks for active teammates and fails if any are still running -- shut them down first. Teammates should never run cleanup themselves.
