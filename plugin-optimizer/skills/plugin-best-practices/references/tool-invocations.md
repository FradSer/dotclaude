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

## Anti-Patterns to Avoid

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

## Quick Reference

| Tool | Style | Example |
|------|-------|---------|
| Read, Write, Edit, Glob, Grep | Implicit | "Find files matching...", "Read the file..." |
| Bash | Implicit | "Run `git status`", "Check with `npm test`" |
| Task | Implicit | "Launch `plugin-name:agent-name` agent" |
| **MCP Tools** | **Implicit** | "Query data source...", "Fetch from API...", "Search external service..." |
| Skill | **Explicit** | "**Load `plugin-name:skill-name` skill** using the Skill tool" |
| TaskCreate | **Explicit** | "**Use TaskCreate tool** to track progress" |
| AskUserQuestion | **Explicit** | "Use `AskUserQuestion` tool to [action]" |
| WebFetch/WebSearch | **Explicit** | "Use WebFetch tool to read docs" |
