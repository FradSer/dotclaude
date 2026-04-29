# Plugin Manifest Schema

The `.claude-plugin/plugin.json` file defines your plugin's metadata and configuration. This section documents all supported fields.

The manifest itself is optional. When omitted, Claude Code auto-discovers components in their default locations and derives the plugin name from the directory name. Use a manifest when you need to provide metadata, custom paths, or non-default configuration.

## Complete schema

```json
{
  "$schema": "https://json.schemastore.org/claude-code-plugin-manifest.json",
  "name": "plugin-name",
  "version": "1.2.0",
  "description": "Brief plugin description",
  "author": {
    "name": "Author Name",
    "email": "author@example.com",
    "url": "https://github.com/author"
  },
  "homepage": "https://docs.example.com/plugin",
  "repository": "https://github.com/author/plugin",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "skills": "./custom/skills/",
  "commands": ["./custom/commands/special.md"],
  "agents": "./custom/agents/",
  "hooks": "./config/hooks.json",
  "mcpServers": "./mcp-config.json",
  "outputStyles": "./styles/",
  "themes": "./themes/",
  "lspServers": "./.lsp.json",
  "monitors": "./monitors.json",
  "userConfig": { "...": "..." },
  "channels": [{ "...": "..." }],
  "dependencies": [
    "helper-lib",
    { "name": "secrets-vault", "version": "~2.1.0" }
  ]
}
```

## Required field

If you ship a manifest, `name` is the only required field.

| Field  | Type   | Description                               | Example              |
| :----- | :----- | :---------------------------------------- | :------------------- |
| `name` | string | Unique identifier (kebab-case, no spaces) | `"deployment-tools"` |

The name is used for namespacing — agent `agent-creator` in plugin `plugin-dev` appears as `plugin-dev:agent-creator`.

## Metadata fields

| Field         | Type   | Description                                                                                                                                        |
| :------------ | :----- | :------------------------------------------------------------------------------------------------------------------------------------------------- |
| `$schema`     | string | JSON Schema URL for editor autocomplete. Ignored at load time.                                                                                     |
| `version`     | string | Semantic version. If set, users only get updates when bumped. If omitted, Claude Code falls back to the git commit SHA.                            |
| `description` | string | Brief explanation of plugin purpose                                                                                                                |
| `author`      | object | Author information (`name`, `email`, `url`)                                                                                                        |
| `homepage`    | string | Documentation URL                                                                                                                                  |
| `repository`  | string | Source code URL                                                                                                                                    |
| `license`     | string | License identifier (e.g. `"MIT"`, `"Apache-2.0"`)                                                                                                  |
| `keywords`    | array  | Discovery tags                                                                                                                                     |

## Component path fields

| Field          | Type                  | Description                                                                                                                            | Example                                |
| :------------- | :-------------------- | :------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------- |
| `skills`       | string\|array         | Custom skill directories containing `<name>/SKILL.md` (replaces default `skills/`)                                                     | `"./custom/skills/"`                   |
| `commands`     | string\|array         | Flat `.md` skill files or skill directories (replaces default `commands/`)                                                             | `["./skills/commit/"]`                 |
| `agents`       | string\|array         | Custom agent files or directories (replaces default `agents/`)                                                                         | `"./custom-agents/"`                   |
| `hooks`        | string\|array\|object | Hook config path or inline configuration (additive — combines with default `hooks/hooks.json`)                                         | `"./extra-hooks.json"`                 |
| `mcpServers`   | string\|array\|object | MCP config path or inline configuration (additive — combines with default `.mcp.json`)                                                 | `"./mcp-config.json"`                  |
| `outputStyles` | string\|array         | Custom output style files/directories (replaces default `output-styles/`)                                                              | `"./styles/"`                          |
| `themes`       | string\|array         | Color theme files/directories (replaces default `themes/`)                                                                             | `"./themes/"`                          |
| `lspServers`   | string\|array\|object | LSP server configurations (additive)                                                                                                   | `"./.lsp.json"`                        |
| `monitors`     | string\|array         | Background monitor configurations (replaces default `monitors/monitors.json`). See `./components/monitors.md`.                         | `"./monitors.json"`                    |

## Plugin configuration fields

| Field          | Type   | Description                                                                                                                                                  |
| :------------- | :----- | :----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `userConfig`   | object | User-configurable values prompted at enable time. Each option requires `type` (`string\|number\|boolean\|directory\|file`), `title`, and `description`.     |
| `channels`     | array  | Message-injection channels (Telegram/Slack/Discord-style). Each entry needs `server` matching a key in `mcpServers`.                                         |
| `dependencies` | array  | Other plugins this one requires. Entries are either `"plugin-name"` strings or `{ "name": "...", "version": "~1.0.0" }` objects.                            |

`userConfig` values are exposed in MCP/LSP/hook/monitor commands as `${user_config.<key>}` and as `CLAUDE_PLUGIN_OPTION_<KEY>` environment variables. Set `"sensitive": true` to mask input and store the value in the system keychain.

## Path behavior rules

For `skills`, `commands`, `agents`, `outputStyles`, `themes`, and `monitors`, a custom path **replaces** the default directory. To keep the default and add more, include the default path explicitly:

```json
{ "skills": ["./skills/", "./extras/"] }
```

`hooks`, `mcpServers`, and `lspServers` use additive semantics — values declared in the manifest layer combine with files at the standard locations.

* All paths MUST be relative to the plugin root and start with `./`
* Components from custom paths use the same naming and namespacing rules
* When a skill path points to a directory containing `SKILL.md` directly (e.g. `"./"`), the frontmatter `name` field determines the invocation name; otherwise the directory basename is used.

**Path examples**:

```json
{
  "commands": [
    "./skills/commit/",
    "./skills/config-git/"
  ],
  "agents": [
    "./custom-agents/reviewer.md",
    "./custom-agents/tester.md"
  ]
}
```

## Environment variables

| Variable                | Description                                                                                                                                       |
| :---------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------ |
| `${CLAUDE_PLUGIN_ROOT}` | Absolute path to the plugin's installation directory. Use for bundled scripts/configs. Files written here do not survive plugin updates.          |
| `${CLAUDE_PLUGIN_DATA}` | Persistent state directory at `~/.claude/plugins/data/<id>/`. Survives plugin updates. Use for `node_modules`, virtualenvs, caches, generated code. |
| `${ENV_VAR}`            | Any process-environment variable. Useful for secrets in `mcpServers`/`lspServers`/`monitors` configs.                                             |
| `${user_config.<key>}`  | Substitutes a value from `userConfig`. Available in MCP/LSP/hook/monitor commands.                                                                |

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/process.sh"
          }
        ]
      }
    ]
  }
}
```

## Plugin installation scopes

When installed, plugins use the standard Claude Code scope system:

| Scope     | Settings file                 | Use case                                                 |
| :-------- | :---------------------------- | :------------------------------------------------------- |
| `user`    | `~/.claude/settings.json`     | Personal plugins available across all projects (default) |
| `project` | `.claude/settings.json`       | Team plugins shared via version control                  |
| `local`   | `.claude/settings.local.json` | Project-specific plugins, gitignored                     |
| `managed` | Managed settings              | Read-only, update-only deployments                       |

## Plugin caching and file resolution

Marketplace plugins are copied to `~/.claude/plugins/cache` rather than loaded in-place, so paths must stay inside the plugin root.

### Path traversal limitations

Paths that traverse outside the plugin root (e.g. `../shared-utils`) will not resolve after installation because external files are not copied to the cache.

### Working with external dependencies

Use a symlink inside the plugin directory; symlinks are preserved during caching and resolve at runtime:

```bash
ln -s /path/to/shared-utils ./shared-utils
```

This pattern provides flexibility while keeping the security benefits of the cache layout.
