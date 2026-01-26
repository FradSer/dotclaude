# Tool Invocation Patterns

Best practices for referencing tools in plugin components.

## Core Principle

**Implicit Tool Usage**: Core file operations (Read, Write, Glob, Grep, Edit) SHOULD be described implicitly. Claude automatically infers the correct tool from context.

## Tool Invocation Rules

### Implicit (Describe Action Directly)

**Core File Operations:**
- Read, Write, Glob, Grep, Edit
- Bash (describe commands: "Run `git status`")
- Task (describe agent launch: "Launch `plugin-name:agent-name` agent")

```markdown
# Good Examples
Find all plugin files matching `**/*.md`
Read each file and extract frontmatter
Search for "TODO" patterns in the codebase
Run `git status` to check changes
Launch `plugin-optimizer:plugin-optimizer` agent to validate structure
Launch the Explore agent to analyze codebase
```

**Qualified Names for Task/Skill**:
- Plugin components: Use `plugin-name:component-name` format
- Claude Code built-ins: Use component name directly (e.g., "Explore agent", "Plan agent")

### Explicit (State Tool Name)

**Workflow & External Tools:**
- Skill: "**Load `plugin-name:skill-name` skill** using the Skill tool"
- AskUserQuestion: "Use `AskUserQuestion` tool to [action]"
- TaskCreate: "**Use TaskCreate tool** to track progress"
- WebFetch, WebSearch: "Use WebFetch tool to read docs"

```markdown
# Good Examples
**Load `plugin-optimizer:plugin-best-practices` skill** using the Skill tool
**Load `git:conventional-commits` skill** using the Skill tool
Use `AskUserQuestion` tool to ask user about migration options
Use `AskUserQuestion` tool to get user confirmation before applying fixes
**Use TaskCreate tool** to track validation progress
Use WebFetch tool to read official documentation
```

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
Use Task tool to launch validator agent

# Good - Implicit descriptions
Find files matching the pattern
Read each file and extract data
Run `git status` to check changes
Launch the validator agent
```

## Quick Reference

| Tool | Style | Example |
|------|-------|---------|
| Read, Write, Edit, Glob, Grep | Implicit | "Find files matching...", "Read the file..." |
| Bash | Implicit | "Run `git status`", "Check with `npm test`" |
| Task | Implicit | "Launch `plugin-name:agent-name` agent", "Launch Explore agent" |
| Skill | **Explicit** | "**Load `plugin-name:skill-name` skill** using the Skill tool" |
| TaskCreate | **Explicit** | "**Use TaskCreate tool** to track progress" |
| AskUserQuestion | **Explicit** | "Use `AskUserQuestion` tool to [action]" |
| WebFetch/WebSearch | **Explicit** | "Use WebFetch tool to read docs" |
