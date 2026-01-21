# Tool Invocation Patterns

Best practices for referencing tools in plugin components.

## Core Principle

**Implicit Tool Usage**: Core file operations (Read, Write, Glob, Grep, Edit) should be described implicitly. Claude automatically infers the correct tool from context.

## Tool Invocation Rules

### Implicit (Describe Action Directly)

**Core File Operations:**
- Read, Write, Glob, Grep, Edit
- Bash (describe commands: "Run `git status`")
- Task (describe agent launch: "Launch code-reviewer agent")

```markdown
# Good Examples
Find all plugin files matching `**/*.md`
Read each file and extract frontmatter
Search for "TODO" patterns in the codebase
Run `git status` to check changes
Launch the validator agent to check compliance
```

### Explicit (State Tool Name)

**Workflow & External Tools:**
- Skill: "**Load X skill** using the Skill tool"
- AskUserQuestion: "Use AskUserQuestion tool to confirm"
- TodoWrite: "**Use TodoWrite tool** to track progress"
- WebFetch, WebSearch: "Use WebFetch tool to read docs"

```markdown
# Good Examples
**Load the hookify:writing-rules skill** using the Skill tool
Use AskUserQuestion tool to let user select options
**Use TodoWrite tool** to track validation progress
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
| Task | Implicit | "Launch X agent", "Use a Haiku agent to..." |
| Skill | **Explicit** | "**Load X skill** using the Skill tool" |
| TodoWrite | **Explicit** | "**Use TodoWrite tool** to track progress" |
| AskUserQuestion | Explicit | "Use AskUserQuestion tool to confirm" |
| WebFetch/WebSearch | Explicit | "Use WebFetch tool to read docs" |
