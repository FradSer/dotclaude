# Create custom subagents

Create and use specialized AI subagents in Claude Code for task-specific workflows and improved context management.

Subagents are specialized AI assistants that handle specific types of tasks. Each subagent runs in its own context window with a custom system prompt, specific tool access, and independent permissions. When Claude encounters a task that matches a subagent’s description, it delegates to that subagent, which works independently and returns results.

Subagents help you:
*   **Preserve context** by keeping exploration and implementation out of your main conversation
*   **Enforce constraints** by limiting which tools a subagent can use
*   **Reuse configurations** across projects with user-level subagents
*   **Specialize behavior** with focused system prompts for specific domains
*   **Control costs** by routing tasks to faster, cheaper models like Haiku

## Built-in subagents

Claude Code includes built-in subagents that Claude automatically uses when appropriate.

*   **Explore**: A fast, read-only agent optimized for searching and analyzing codebases (uses Haiku).
*   **Plan**: A research agent used during plan mode to gather context before presenting a plan.
*   **General-purpose**: A capable agent for complex, multi-step tasks that require both exploration and action.
*   **Helper Agents**: Includes `Bash`, `statusline-setup`, and `Claude Code Guide`.

## Quickstart: create your first subagent

1.  **Open the interface**: Run `/agents` in Claude Code.
2.  **Create a new agent**: Select **Create new agent**, then choose **User-level** (saves to `~/.claude/agents/`).
3.  **Generate with Claude**: Provide a description, e.g., "A code improvement agent that scans files and suggests improvements."
4.  **Select tools**: Choose allowed tools (e.g., Read-only tools for a reviewer).
5.  **Select model**: Choose a model (e.g., Sonnet).
6.  **Choose a color**: Pick a UI background color.
7.  **Save and try it out**: Use it immediately with commands like `Use the code-improver agent to suggest improvements`.

## Configure subagents

### Subagent Scope
Subagents are Markdown files with YAML frontmatter stored in different locations:

| Location | Scope | Priority |
| :--- | :--- | :--- |
| `--agents` CLI flag | Current session | 1 (highest) |
| `.claude/agents/` | Current project | 2 |
| `~/.claude/agents/` | All your projects | 3 |
| Plugin `agents/` dir | Where plugin is enabled | 4 |

### Write subagent files
Files use YAML frontmatter for configuration and Markdown for the system prompt.

```markdown
---
name: code-reviewer
description: Reviews code for quality and best practices
tools: Read, Glob, Grep
model: sonnet
---

You are a code reviewer. Analyze the code and provide actionable feedback...
```

### Supported frontmatter fields
*   `name`: Unique identifier (lowercase and hyphens).
*   `description`: When Claude should delegate to this subagent.
*   `tools` / `disallowedTools`: List of allowed/denied tools.
*   `model`: `sonnet`, `opus`, `haiku`, or `inherit`.
*   `permissionMode`: `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, or `plan`.
*   `skills`: List of skills to load into the subagent's context.
*   `hooks`: Lifecycle hooks scoped to the subagent.

## Control subagent capabilities

### Permission modes
*   `default`: Standard prompts.
*   `acceptEdits`: Auto-accept file edits.
*   `dontAsk`: Auto-deny prompts (only explicit tools work).
*   `bypassPermissions`: Skip all permission checks (use with caution).

### Conditional rules with hooks
Use `PreToolUse` hooks to validate operations. For example, to enforce read-only database queries:

```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-readonly-query.sh"
```

The validation script can read the tool input via JSON and exit with code 2 to block the operation.

## Work with subagents

*   **Automatic Delegation**: Claude delegates based on the task and subagent description.
*   **Foreground vs. Background**: Foreground subagents block the conversation and pass prompts to you. Background subagents run concurrently and auto-deny unauthorized prompts. Press **Ctrl+B** to background a task.
*   **Resume subagents**: Each invocation is usually fresh, but you can ask Claude to "Continue that [agent name] work" to retain full conversation history.
*   **Auto-compaction**: Subagents automatically compact context at ~95% capacity.

## Example subagents

### Code reviewer (Read-only)
```markdown
---
name: code-reviewer
description: Expert code review specialist. Use after writing or modifying code.
tools: Read, Grep, Glob, Bash
model: inherit
---
You are a senior code reviewer...
```

### Debugger (With Edit access)
```markdown
---
name: debugger
description: Debugging specialist for errors and test failures.
tools: Read, Edit, Bash, Grep, Glob
---
You are an expert debugger specializing in root cause analysis...
```

### Database query validator (Hook-based)
Utilizes a shell script to block any `INSERT`, `UPDATE`, or `DELETE` commands while allowing `SELECT` via the Bash tool.
