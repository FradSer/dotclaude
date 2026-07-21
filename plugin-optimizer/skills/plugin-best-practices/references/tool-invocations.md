# Tool Invocation Patterns

Best practices for referencing tools in plugin components.

**Official MCP Documentation**: https://code.claude.com/docs/en/mcp

## Core Principle

**Implicit Tool Usage**: Core file operations (Read, Write, Glob, Grep, Edit) and MCP tools SHOULD be described implicitly. Claude automatically infers the correct tool from context.

## Tool Invocation Rules

### Implicit (Describe Action Directly)

**Core File Operations**:
- Read, Write, Glob, Grep, Edit
- Bash (describe commands: "Run `git status`")
- Task (describe agent launch: "Launch `plugin-name:agent-name` agent")
- **MCP Tools** (describe intent in natural language)

```markdown
# Good Examples
Find all plugin files matching `**/*.md`
Read each file and extract frontmatter
Search for "TODO" patterns in the codebase
Run `git status` to check changes
Launch `plugin-name:agent-name` agent to validate structure
Launch the Explore agent to analyze codebase
```

**MCP Tool Examples**:
```markdown
# Good - Natural language intent (Claude auto-selects MCP tool)
Query the database for records matching the criteria
Search the web for documentation on the topic
Fetch items from the external service
Retrieve data from the API
Check monitoring for recent alerts
Create a draft in the external system
```

**Qualified Names for Task/Skill**:
- Plugin components: Use `plugin-name:component-name` format
- Claude Code built-ins: Use component name directly (e.g., "Explore agent", "Plan agent")

### Explicit (State Tool Name)

**Workflow & External Tools**:
- Skill: "**Load `plugin-name:skill-name` skill** using the Skill tool"
- AskUserQuestion: "Use `AskUserQuestion` tool to [action]"
- TaskCreate: "**Use TaskCreate tool** to track progress"
- WebFetch, WebSearch: "Use WebFetch tool to read docs"

```markdown
# Good Examples
**Load `plugin-name:skill-name` skill** using the Skill tool
Use `AskUserQuestion` tool to ask user about options
**Use TaskCreate tool** to track progress
Use WebFetch tool to read official documentation
```

## MCP Tool Invocation

**Official Documentation**: https://code.claude.com/docs/en/mcp

### Key Principle

Always use **natural language** to describe intent. Claude automatically selects the appropriate MCP tool.

**Never reference internal MCP tool names** (`mcp__server__tool`) in skill content.

### Correct vs Wrong Patterns

```markdown
# Correct - Natural language intent
Query the data source for matching records
Search the external service for items
Fetch the latest data from the API
Check the monitoring system for alerts

# Wrong - Explicit tool naming
Call mcp__server__tool_name to get data
Use mcp__service__function to find items
Execute mcp__api__endpoint
```

### When MCP Tools Are Available

MCP tools become available when:
- User has configured MCP servers (via `claude mcp add` or `.mcp.json`)
- Plugin bundles MCP servers in `.mcp.json` or `plugin.json`
- Servers are enabled and running

Check available servers: `/mcp`

## In allowed-tools Configuration

Always use array syntax with filters for Bash:

```yaml
# Commands/Agents frontmatter
allowed-tools: ["Read", "Glob", "Grep", "Bash(git:*)"]

# Common filters
Bash(git:*)           # Git commands only
Bash(npm:*)           # NPM commands only
Bash(gh pr:*)         # GitHub PR commands only
```

**Never use bare `Bash`** - always specify command filters.

## Inline Bash Execution

In command files, use inline syntax for dynamic context:

```markdown
Current branch: !`git branch --show-current`
Modified files: !`git diff --name-only`
```

Format: `!`command`` (exclamation + backtick + command + backtick)

## External Services Token Isolation (Critical)

When using external search services (Exa, WebSearch, etc.), **never run them in the main context**. Always spawn a Task agent to handle searches to avoid polluting the conversation context with large search results.

### Why It Matters

External search services can return large volumes of content (code snippets, documentation, StackOverflow answers). Running these directly in the main context:
- Consumes significant token budget
- Mixes unrelated results from different searches
- Makes it harder to find relevant information in conversation history

### Pattern

```
Launch Task agent to search for [topic]
  → Agent runs Exa/WebSearch MCP tool
  → Agent extracts minimum viable snippets + constraints
  → Agent deduplicates near-identical results (mirrors, forks, repeated answers)
  → Agent returns copyable snippets + brief explanation
Main context stays clean regardless of search volume
```

### Good Examples

```markdown
# Correct - Use Task agent for external searches
Launch Task agent to research authentication best practices
Launch Task agent to find relevant code examples online
Launch Task agent to search for current documentation

# Wrong - Running searches in main context
Search the web for authentication best practices
Query external service for code examples
```

### When to Apply

Use this pattern when:
- Web search for current information
- Code search services (Exa, GitHub search, etc.)
- Any external API returning large response volumes
- Multi-step research requiring multiple queries

This keeps the main conversation context clean and token-efficient.

```markdown
# Bad - Explicit tool calls for core operations
Use Glob tool to find files
Use Read tool to read each file
Use Bash tool to run git status
Call mcp__server__tool to get data

# Good - Implicit descriptions
Find files matching the pattern
Read each file and extract data
Run `git status` to check changes
Query the data source for records
```

## Bundled Script Paths (Critical)

When a skill/command/agent instructs the agent to run a script bundled with the plugin, **always address the script by its absolute plugin path via `${CLAUDE_PLUGIN_ROOT}`** — never by a bare relative path like `scripts/foo.sh` or `./scripts/foo.sh`.

**Why this matters:** the skill's working directory is the **target repo** (the user's project, the PR's repository, the plan folder), NOT the plugin directory. A bare `scripts/foo.sh` resolves against the cwd, so it points at a file that does not exist in the target repo, and the agent reports "the referenced script doesn't exist in this repo." This bug is silent in authoring (the path looks fine in the plugin source) and only surfaces at runtime in a different repo.

**MUST — executable instructions use `${CLAUDE_PLUGIN_ROOT}`:**

```markdown
# Good — resolves regardless of cwd
Run `bash "${CLAUDE_PLUGIN_ROOT}/skills/review-pr/scripts/review-loop.sh"`
Launch a Monitor running `${CLAUDE_PLUGIN_ROOT}/skills/executing-plans/scripts/batch-progress.sh`

# Bad — breaks the moment the skill runs in a target repo
Run `scripts/review-loop.sh`              # cwd is the PR's repo, not the plugin
Launch a Monitor running `scripts/batch-progress.sh`
```

**Drift trap:** a skill's L2 `SKILL.md` body and its L3 `references/*.md` are often written separately. If the L3 uses `${CLAUDE_PLUGIN_ROOT}` but the L2 executable instruction drifts back to a bare `scripts/...`, the L2 is the one that runs — and it fails. Keep both layers consistent; when fixing one, grep the other.

**Allowed bare paths (NOT bugs):**
- Descriptive pointers in a **References** section: `- ./scripts/foo.sh - what it does`. Documentation, not executed.
- **Upstream mirrors** whose paths are resolved by an external CLI at install time (e.g. hyperframes uses `<SKILL_DIR>`, impeccable uses `.claude/skills/...`). These are an install-time convention, not a runtime bare path — the placeholder (`<SKILL_DIR>`, `<MEDIA_DIR>`) is the tell.
- Prose naming the script's location without instructing execution: "the script lives at `scripts/foo.sh`" — provided the executable instruction in the same doc uses the absolute path.

**The line between bug and benign is semantic, not syntactic** — the same text shape (`scripts/foo.sh` inside backticks) can be a real executable instruction or a descriptive reference. A static checker cannot reliably tell them apart, so the rule is enforced by review, not by `validate-plugin.py`. Run the advisory audit after touching any skill that bundles a script:

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/audit-bare-paths.py <plugin-dir-or-.>
```

It lists every bare `scripts/...` candidate with a reason; judge each against the skill's cwd contract.

## Quick Reference

| Tool | Style | Example |
|------|-------|---------|
| Read, Write, Edit, Glob, Grep | Implicit | "Find files matching...", "Read the file..." |
| Bash | Implicit | "Run `git status`", "Check with `npm test`" |
| Task (code/search) | Implicit | "Launch Task agent to search for..." |
| Task (workflow) | Implicit | "Launch `plugin-name:agent-name` agent" |
| **MCP Tools** | **Implicit** | "Query data source...", "Fetch from API..." |
| External Search (Exa/WebSearch) | **Task Agent** | "Launch Task agent to search for..." |
| Skill | **Explicit** | "**Load `plugin-name:skill-name` skill** using the Skill tool" |
| TaskCreate | **Explicit** | "**Use TaskCreate tool** to track progress" |
| AskUserQuestion | **Explicit** | "Use `AskUserQuestion` tool to [action]" |
| WebFetch/WebSearch | **Explicit** | "Use WebFetch tool to read docs" |
