# Agent Teams

Teams of Claude Code sessions that work together on shared tasks with centralized management.

## When to Use

- **Parallelizable Tasks**: Tasks that can be broken down into independent subtasks (e.g., "refactor these 5 files", "write tests for these modules").
- **Multi-perspective Analysis**: Tasks requiring different viewpoints (e.g., "one teammate on UX, one on security").
- **Complex Research**: Tasks needing extensive information gathering from multiple sources.

## Enabling

Agent Teams is currently experimental. Enable it via environment variable or configuration:

**Environment Variable:**
```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

**Settings (`~/.claude/settings.json`):**
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

## Starting a Team

You can start a team by explicitly asking Claude:

> "Create an agent team to refactor the database layer. One teammate for schema changes, one for migration scripts."

Or Claude may propose it for complex tasks.

## Controlling Teammates

### Display Modes

Set via `teammateMode` in settings or CLI flag `--teammate-mode`.

1.  **In-process (`in-process`)**:
    - Runs in the main terminal.
    - Use `Shift+Up/Down` to select teammates.
    - Works everywhere.
    - *Limitation*: No session resumption (`/resume`).

2.  **Split Panes (`tmux` / `auto`)**:
    - Requires `tmux` or iTerm2 (with Python API).
    - Each teammate gets a pane.
    - Better visibility.

### Commands

- **Assign Tasks**: Tell the lead "Assign the API task to the backend teammate".
- **Direct Talk**: Select teammate (Shift+Up/Down) or click pane to message directly.
- **Shutdown**: "Ask the researcher to shut down" or "Clean up the team" to stop all.

## Best Practices

1.  **Context**: Give teammates specific instructions and context in their prompt.
    - *Good*: "Review `src/auth` for security flaws, focusing on JWT handling."
    - *Bad*: "Review the code."
2.  **Task Sizing**:
    - Avoid tiny tasks (overhead > benefit).
    - Avoid huge tasks (risk of going off-track).
3.  **Wait**: Explicitly tell the lead to "Wait for teammates to finish" if coordination is needed.
4.  **Files**: Assign distinct files/modules to avoid conflicts.

## Limitations

- **No Resumption**: In-process teams cannot be restored after `/resume`.
- **One Team**: Only one team per session.
- **No Nesting**: Teammates cannot spawn sub-teams.
- **Fixed Lead**: The starting session is always the lead.
