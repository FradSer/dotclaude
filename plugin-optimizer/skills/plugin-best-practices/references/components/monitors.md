# Monitors Component Reference

Plugins can declare background monitors that Claude Code starts automatically when the plugin is active. Each monitor runs a shell command for the lifetime of the session and delivers every stdout line to Claude as a notification — useful for log entries, status changes, or polled events that Claude should react to without being asked to start the watch.

Plugin monitors share the [Monitor tool](https://code.claude.com/docs/en/tools-reference#monitor-tool) availability constraints: interactive CLI sessions only, unsandboxed at the same trust level as hooks, skipped on hosts where the Monitor tool is unavailable.

> **Version**: Plugin monitors require Claude Code v2.1.105 or later.

## Location

* `monitors/monitors.json` in the plugin root, OR
* `"monitors"` key in `plugin.json` with either an inline array or a relative path string

## Format

A JSON array of monitor entries:

```json
[
  {
    "name": "deploy-status",
    "command": "${CLAUDE_PLUGIN_ROOT}/scripts/poll-deploy.sh ${user_config.api_endpoint}",
    "description": "Deployment status changes"
  },
  {
    "name": "error-log",
    "command": "tail -F ./logs/error.log",
    "description": "Application error log",
    "when": "on-skill-invoke:debug"
  }
]
```

## Required fields

| Field         | Description                                                                                                            |
| :------------ | :--------------------------------------------------------------------------------------------------------------------- |
| `name`        | Identifier unique within the plugin. Prevents duplicate processes when the plugin reloads or a skill re-fires.         |
| `command`     | Shell command run as a persistent background process in the session working directory.                                 |
| `description` | Short summary of what is being watched. Shown in the task panel and in notification summaries.                         |

## Optional fields

| Field  | Description                                                                                                                                                       |
| :----- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `when` | When the monitor starts. `"always"` (default) starts at session start and on plugin reload. `"on-skill-invoke:<skill-name>"` starts on first dispatch of the skill. |

## Variable substitution

The `command` field supports the same substitutions as MCP and LSP server configs:

* `${CLAUDE_PLUGIN_ROOT}` — plugin install directory
* `${CLAUDE_PLUGIN_DATA}` — persistent data directory
* `${user_config.KEY}` — user-configured plugin options
* `${ENV_VAR}` — process environment

If the command needs the plugin directory as cwd, prefix it explicitly: `cd "${CLAUDE_PLUGIN_ROOT}" && ./script.sh`.

## Behavior

* Monitor stdout is delivered to Claude line-by-line as notifications
* Disabling a plugin mid-session does **not** stop already-running monitors; they stop only at session end
* Each `name` can only have one running instance — useful if a plugin is reloaded or a triggering skill is invoked twice

## When to choose monitors over alternatives

| Need                                                          | Use                |
| :------------------------------------------------------------ | :----------------- |
| Stream lines from a long-running process to Claude            | **Monitor**        |
| React to a one-shot lifecycle event (e.g. `PostToolUse`)      | Hook               |
| Poll on demand inside a skill                                 | Bash + Monitor tool |
| Connect external tools and resources to Claude                | MCP server         |

## Example: deploy watcher with user-configured endpoint

```json
{
  "userConfig": {
    "api_endpoint": {
      "type": "string",
      "title": "Deploy API endpoint",
      "description": "Base URL of the deployment status API"
    }
  },
  "monitors": [
    {
      "name": "deploy-status",
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/poll-deploy.sh ${user_config.api_endpoint}",
      "description": "Deployment status changes"
    }
  ]
}
```

The corresponding script should print one line per status change so each becomes a separate Claude notification.

## Best practices

* **Output discipline**: every stdout line becomes a Claude notification. Suppress or rate-limit chatty sources before they reach the monitor.
* **Idempotent startup**: assume the script may be (re)started across sessions. Avoid bootstrapping side effects.
* **Failure handling**: log to stderr, not stdout, for diagnostics that should not become notifications.
* **`when: on-skill-invoke:<skill>`** keeps cost low for monitors that are only relevant to a specific workflow.
