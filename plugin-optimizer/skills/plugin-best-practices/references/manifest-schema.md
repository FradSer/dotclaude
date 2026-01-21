# Plugin Manifest Schema

The `plugin.json` file defines your plugin's metadata and configuration. This section documents all supported fields and options.

## Complete schema

```json
{
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
  "commands": ["./custom/commands/special.md"],
  "agents": "./custom/agents/",
  "skills": "./custom/skills/",
  "hooks": "./config/hooks.json",
  "mcpServers": "./mcp-config.json",
  "outputStyles": "./styles/",
  "lspServers": "./.lsp.json"
}
```

## Required fields

| Field  | Type   | Description                               | Example              |
| :----- | :----- | :---------------------------------------- | :------------------- |
| `name` | string | Unique identifier (kebab-case, no spaces) | `"deployment-tools"` |

## Metadata fields

| Field         | Type   | Description                         | Example                                            |
| :------------ | :----- | :---------------------------------- | :------------------------------------------------- |
| `version`     | string | Semantic version                    | `"2.1.0"`                                          |
| `description` | string | Brief explanation of plugin purpose | `"Deployment automation tools"`                    |
| `author`      | object | Author information                  | `{"name": "Dev Team", "email": "dev@company.com"}` |
| `homepage`    | string | Documentation URL                   | `"https://docs.example.com"`                       |
| `repository`  | string | Source code URL                     | `"https://github.com/user/plugin"`                 |
| `license`     | string | License identifier                  | `"MIT"`, `"Apache-2.0"`                            |
| `keywords`    | array  | Discovery tags                      | `["deployment", "ci-cd"]`                          |

## Component path fields

| Field          | Type           | Description                                                                                                                                              | Example                                |
| :------------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------- |
| `commands`     | string\|array  | Additional command files/directories                                                                                                                     | `"./custom/cmd.md"` or `["./cmd1.md"]` |
| `agents`       | string\|array  | Additional agent files                                                                                                                                   | `"./custom/agents/"`                   |
| `skills`       | string\|array  | Additional skill directories                                                                                                                             | `"./custom/skills/"`                   |
| `hooks`        | string\|object | Hook config path or inline config                                                                                                                        | `"./hooks.json"`                       |
| `mcpServers`   | string\|object | MCP config path or inline config                                                                                                                         | `"./mcp-config.json"`                  |
| `outputStyles` | string\|array  | Additional output style files/directories                                                                                                                | `"./styles/"`                          |
| `lspServers`   | string\|object | [Language Server Protocol](https://microsoft.github.io/language-server-protocol/) config for code intelligence (go to definition, find references, etc.) | `"./.lsp.json"`                        |

## Path behavior rules

**Important**: Custom paths supplement default directories - they don't replace them.

* If `commands/` exists, it's loaded in addition to custom command paths
* All paths must be relative to plugin root and start with `./`
* Commands from custom paths use the same naming and namespacing rules
* Multiple paths can be specified as arrays for flexibility

**Path examples**:

```json
{
  "commands": [
    "./specialized/deploy.md",
    "./utilities/batch-process.md"
  ],
  "agents": [
    "./custom-agents/reviewer.md",
    "./custom-agents/tester.md"
  ]
}
```

## Environment variables

**`${CLAUDE_PLUGIN_ROOT}`**: Contains the absolute path to your plugin directory. Use this in hooks, MCP servers, and scripts to ensure correct paths regardless of installation location.

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

When you install a plugin, you choose a **scope** that determines where the plugin is available and who else can use it:

| Scope     | Settings file                 | Use case                                                 |
| :-------- | :---------------------------- | :------------------------------------------------------- |
| `user`    | `~/.claude/settings.json`     | Personal plugins available across all projects (default) |
| `project` | `.claude/settings.json`       | Team plugins shared via version control                  |
| `local`   | `.claude/settings.local.json` | Project-specific plugins, gitignored                     |
| `managed` | `managed-settings.json`       | Managed plugins (read-only, update only)                 |

Plugins use the same scope system as other Claude Code configurations. For installation instructions and scope flags, see [Install plugins](/en/discover-plugins#install-plugins). For a complete explanation of scopes, see [Configuration scopes](/en/settings#configuration-scopes).

## Plugin caching and file resolution

For security and verification purposes, Claude Code copies plugins to a cache directory rather than using them in-place. Understanding this behavior is important when developing plugins that reference external files.

### How plugin caching works

When you install a plugin, Claude Code copies the plugin files to a cache directory:

* **For marketplace plugins with relative paths**: The path specified in the `source` field is copied recursively. For example, if your marketplace entry specifies `"source": "./plugins/my-plugin"`, the entire `./plugins` directory is copied.
* **For plugins with `.claude-plugin/plugin.json`**: The implicit root directory (the directory containing `.claude-plugin/plugin.json`) is copied recursively.

### Path traversal limitations

Plugins cannot reference files outside their copied directory structure. Paths that traverse outside the plugin root (such as `../shared-utils`) will not work after installation because those external files are not copied to the cache.

### Working with external dependencies

If your plugin needs to access files outside its directory, you have two options:

**Option 1: Use symlinks**

Create symbolic links to external files within your plugin directory. Symlinks are honored during the copy process:

```bash
# Inside your plugin directory
ln -s /path/to/shared-utils ./shared-utils
```

The symlinked content will be copied into the plugin cache.

**Option 2: Restructure your marketplace**

Set the plugin path to a parent directory that contains all required files, then provide the rest of the plugin manifest directly in the marketplace entry:

```json
{
  "name": "my-plugin",
  "source": "./",
  "description": "Plugin that needs root-level access",
  "commands": ["./plugins/my-plugin/commands/"],
  "agents": ["./plugins/my-plugin/agents/"],
  "strict": false
}
```

This approach copies the entire marketplace root, giving your plugin access to sibling directories.

> **Note**: Symlinks that point to locations outside the plugin's logical root are followed during copying. This provides flexibility while maintaining the security benefits of the caching system.
