# Connect Claude Code to Tools via MCP

Claude Code uses the **Model Context Protocol (MCP)**, an open-source standard that allows the AI to connect to external tools, databases, and APIs.

## 1. Installation Options
MCP servers are added using the `claude mcp add` command. Options and flags must come **before** the server name, followed by a double dash `--` for the command arguments.

### Option 1: Remote HTTP (Recommended)
Best for cloud-based services.
```bash
# Basic syntax
claude mcp add --transport http <name> <url>

# Example: Connect to Notion
claude mcp add --transport http notion https://mcp.notion.com/mcp

# Example: With Bearer token
claude mcp add --transport http secure-api https://api.example.com/mcp \
  --header "Authorization: Bearer your-token"
```

### Option 2: Local Stdio
Best for tools requiring direct system access or custom scripts.
```bash
# Basic syntax
claude mcp add [options] <name> -- <command> [args...]

# Example: Add Airtable server
claude mcp add --transport stdio --env AIRTABLE_API_KEY=YOUR_KEY airtable \
  -- npx -y airtable-mcp-server
```
*   **Windows Note:** Use `cmd /c` before `npx` (e.g., `cmd /c npx -y @some/package`).

## 2. Managing Servers
| Command | Description |
| :--- | :--- |
| `claude mcp list` | List all configured servers. |
| `claude mcp get <name>` | Get details for a specific server. |
| `claude mcp remove <name>` | Remove a server. |
| `/mcp` | (Inside Claude Code) Check status or authenticate via OAuth. |

## 3. Installation Scopes
*   **`local` (default):** Private to you, specific to the current project.
*   **`project`:** Shared with the team via a `.mcp.json` file in the project root.
*   **`user`:** Available to you across all projects on your machine.

## 4. Key Features
*   **Environment Variables:** Supports expansion in `.mcp.json` using `${VAR}` or `${VAR:-default}`.
*   **Resources:** Reference data using `@mentions`. Format: `@server:protocol://resource/path`.
*   **Slash Commands:** MCP prompts are exposed as `/mcp__servername__promptname`.
*   **Tool Search:** If tool definitions exceed 10% of the context window, Claude dynamically searches for tools on-demand. Configure with `ENABLE_TOOL_SEARCH=auto|true|false`.
*   **Output Limits:** Warnings appear at 10,000 tokens. Adjust the 25,000-token default limit via `MAX_MCP_OUTPUT_TOKENS`.
*   **Claude as a Server:** Run `claude mcp serve` to use Claude Code's tools (Edit, View, LS) inside other applications like Claude Desktop.

## 5. Managed Configuration (Enterprise)
Administrators can control MCP access via a `managed-mcp.json` file or policy-based allowlists/denylists in system directories:
*   **macOS:** `/Library/Application Support/ClaudeCode/managed-mcp.json`
*   **Linux/WSL:** `/etc/claude-code/managed-mcp.json`
*   **Windows:** `C:\Program Files\ClaudeCode\managed-mcp.json`

Restrictions can be applied by `serverName`, `serverCommand` (exact match), or `serverUrl` (supports wildcards like `https://*.internal.corp/*`).