# Command Development Patterns

Complete guide to creating effective commands for Claude Code plugins.

## 2. Command Development

**Must Do**

- **Write Instructions FOR Claude:** Write prompts as directives _to_ the agent (e.g., "Review this code for...\") rather than descriptions _to_ the user (e.g., "This command reviews code...").
- **Use YAML Frontmatter:** Include `description` and `argument-hint` in your `.md` files.
- **Validate Arguments:** Check for required arguments (`$1`, `$2`) inside the prompt logic and handle missing inputs gracefully.

**Should Do**

- **Use Argument Hints:** Define `argument-hint: [arg1] [arg2]` to help users with autocomplete.
- **Limit Tool Access:** Use the `allowed-tools` field to adhere to the principle of least privilege.
- **Prevent Recursion:** Use `disable-model-invocation: true` if your command is purely for user interaction and shouldn't be called autonomously by other agents/skills.
- **Integrate Bash for Dynamic Context:** Use inline bash execution with the correct syntax pattern &#33;&#96;command&#96; (exclamation mark + backtick + command + backtick, backticks required) to gather context dynamically before Claude processes the prompt.

### allowed-tools Syntax

**Supported Tools (by usage frequency in official plugins):**

**Core File Operations:** `Read`, `Write`, `Glob`, `Grep`, `Edit` (**Do NOT explicitly call these tools - describe actions directly**)
**Execution & Control:** `Bash` (**Always use with filters** - Do NOT say "Use Bash tool", describe commands directly), `Task` (**Describe agent launch directly, only use "Use Task tool" when providing JSON**), `Skill` (**Explicitly call: "Load X skill using the Skill tool"**)
**User Interaction:** `AskUserQuestion`, `TodoWrite`
**Web & Network:** `WebFetch`, `WebSearch`
**Notebooks:** `NotebookRead`, `NotebookEdit`
**Shell Management:** `KillShell`, `BashOutput`, `LS`
**MCP Tools:** `mcp__plugin_name__tool_name` (use wildcards: `mcp__plugin_asana__*`)

**Standard Syntax (RECOMMENDED - with quotes):**

```yaml
allowed-tools: ["Read", "Write", "Bash(git:*)", "AskUserQuestion", "Skill"]
```

**Without quotes (also valid):**

```yaml
allowed-tools: [Read, Glob, Grep, Bash(npm:*)]
```

**Common Bash Filters:**

```yaml
# Version control
Bash(git:*)
Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*)

# Package managers & testing
Bash(npm:*), Bash(jest:*)

# Cloud & containers
Bash(docker:*), Bash(kubectl:*)

# GitHub CLI
Bash(gh pr:*), Bash(gh issue:*)
```

**When to use:**

1. **Security:** Restrict to safe operations: `[Read, Grep]` for read-only commands
2. **Clarity:** Document required tools: `[Bash(git:*), Read]`
3. **Bash execution:** Enable inline bash output: `[Bash(git status:*)]`

**Best practices:**

- Be as restrictive as possible
- **NEVER use `Bash` without filters** - Always use `Bash(command:*)` patterns
- Only specify when different from conversation permissions
- Prefer array syntax with quotes for consistency: `["Tool1", "Tool2"]`
- For MCP tools, use wildcard patterns: `mcp__plugin_name__*`

**Inline Bash Execution Syntax:**

```markdown
# CORRECT - Official syntax with backticks
# Format: &#33;&#96;command&#96; (exclamation mark + backtick + command + backtick)

Current git status: &#33;&#96;git status&#96;
Current branch: &#33;&#96;git branch --show-current&#96;
Recent commits: &#33;&#96;git log --oneline -10&#96;

# WRONG - Missing backticks

Current git status: !git status
```

The backticks `` ` `` are **required syntax** - they mark the boundaries of the bash command to be executed. The output is captured and embedded into the prompt context before Claude processes it.

**Avoid**

- **Chatty Prompts:** Don't waste tokens explaining what you are going to do; just provide the instructions to do it.
- **Destructive Defaults:** Avoid running destructive bash commands (delete/overwrite) without explicit user confirmation steps or validation.
