# Tool Invocation Patterns (Official Standards)

Complete guide to proper tool invocation patterns in Claude Code plugin components.

## Core Principle

**Core File Operations tools (Read, Write, Glob, Grep, Edit) should NOT be explicitly called** - simply describe the action directly. Claude will automatically use the appropriate tool. For other tools (Bash, TodoWrite, Skill, Task, AskUserQuestion, WebFetch, WebSearch), explicit invocation may be helpful for clarity.

## 1. File Discovery & Reading

**Glob Tool - Find files by pattern:**

````markdown
Find all hookify rule files matching the pattern:
```
pattern: ".claude/hookify.*.local.md"
```
````

**Read Tool - Read and extract information:**

```markdown
For each file found:

- Read the file
- Extract frontmatter fields: name, enabled, event
- Extract message preview (first 100 chars)
```

**Best practices:**

- **Do NOT say "Use Glob tool" or "Use Read tool"** - just describe the action directly
- Provide patterns in code blocks when needed
- Describe what to extract or examine
- Claude will automatically infer the correct tool from the context

## 2. File Modification

**Write Tool - Create new files:**

````markdown
Create `agents/[identifier].md` with the following content:

```markdown
---
name: [identifier]
description: [Use this agent when...]
model: inherit
---

[System prompt]
```
````

**Edit Tool - Modify existing files:**
````markdown
Read the current content, then update:
```
old_string: "enabled: false"
new_string: "enabled: true"
```
````

**Best practices:**

- **Do NOT say "Use Write tool" or "Use Edit tool"** - just describe the action directly
- Always read before editing when needed
- Show exact old_string/new_string patterns for Edit operations
- Claude will automatically infer the correct tool from the context

## 3. Search & Execution

**Grep Tool - Content search:**

```markdown
tools: Glob, Grep, Read # In agent frontmatter (for allowed-tools configuration)
```

In instructions, simply describe the search:
```markdown
Search for all occurrences of "console.log" in the codebase
Find files containing the pattern "TODO|FIXME"
```

**Bash Tool - Dynamic context:**

```markdown
# Commands: Use inline execution (special syntax)
# Format: &#33;&#96;command&#96; (exclamation mark + backtick + command + backtick)

Current git status: &#33;&#96;git status&#96;
Current branch: &#33;&#96;git branch --show-current&#96;

# Instructions: Describe commands directly (do NOT say "Use Bash tool")

1. **Gather Context**: Run `git diff --name-only` to see modified files
2. Check git status to identify changed files
3. Create a pull request using `gh pr create`
4. Stage the relevant files with `git add`
```

**Best practices:**

- **Do NOT say "Use Bash tool"** - just describe the command directly
- **Inline execution syntax**: Use the pattern &#33;&#96;command&#96; (exclamation mark + backtick + command + backtick) for dynamic context in commands (special case)
- **Direct command description**: "Run `git diff`", "Check git status", "Create PR with `gh pr create`"
- Claude will automatically use Bash tool when it sees a command

## 4. Workflow Orchestration

**TodoWrite - Track progress:**

```markdown
**Use TodoWrite tool** to track progress at every phase
```

**Skill Tool - Load additional context:**

```markdown
**FIRST: Load the hookify:writing-rules skill** using the Skill tool to understand rule file format and syntax.

**Load the [skill-name] skill** to access specialized knowledge about...
```

**Best practices:**

- **Explicit invocation**: Always explicitly say "Load X skill using the Skill tool" or "**FIRST: Load X skill**"
- **Use emphasis**: Bold/uppercase for critical/first-time skill loading
- **Clear purpose**: Explain why the skill is needed

**Task Tool - Launch agents:**

**Method 1: Descriptive (RECOMMENDED - for most cases):**

```markdown
# Describe agent launch directly (do NOT say "Use Task tool" in most cases)

1. Launch 2-3 code-explorer agents in parallel
2. Use a Haiku agent to check if the pull request exists
3. Launch 5 parallel Sonnet agents to independently code review each file
4. Launch all agents simultaneously: code-reviewer, pr-test-analyzer, silent-failure-hunter
```

**Method 2: Explicit Task tool (only when JSON structure needed):**

````markdown
# Only use explicit "Use Task tool" when providing full JSON structure

Use the Task tool to launch conversation-analyzer agent:
```
{
  "subagent_type": "general-purpose",
  "description": "Analyze conversation for unwanted behaviors",
  "prompt": "You are analyzing a Claude Code conversation to find behaviors...

For each issue found, extract:

- What tool was used (Bash, Edit, Write, etc.)
- Specific pattern or command
- Why it was problematic

Return findings as a structured list with:

- category: Type of issue
- tool: Which tool was involved
- pattern: Regex or literal pattern to match
- severity: high/medium/low"
}
```
````

**Best practices:**

- **Most cases**: Describe agent launch directly - "Launch X agent", "Use a Haiku agent to..."
- **Only when needed**: Use explicit "Use Task tool" when providing full JSON structure for general-purpose agents
- **Agent examples**: In agent descriptions, examples may say "I'll use the Task tool to launch..." for clarity, but in commands, descriptive is preferred

**Method 3: Plugin-specific agents:**

```markdown
# Reference agents from your plugin

Launch the code-reviewer agent to check CLAUDE.md compliance
Launch the silent-failure-hunter agent to find error handling issues
```

**Parallel vs Sequential:**

```markdown
# Sequential (one at a time)

1. Use a Haiku agent to check eligibility
2. After it returns, use another Haiku agent to get file list
3. Then launch 5 parallel Sonnet agents for review

# Parallel (explicitly requested)

Launch all agents simultaneously:

- code-reviewer agent
- pr-test-analyzer agent
- silent-failure-hunter agent
```

**Best practices:**

- **Specify model tier**: "Use a Haiku agent" (fast), "launch Sonnet agents" (quality), "use Opus agent" (complex)
- **Describe return value**: "ask the agent to return a summary", "agent should return a list of issues"
- **Descriptive style preferred**: Use descriptive style for both built-in and plugin agents - "Launch code-reviewer agent", "Use silent-failure-hunter agent"
- **Explicit Task tool only when needed**: Only use "Use Task tool" when providing full JSON structure for general-purpose agents
- **Parallel execution**: Explicitly mention "parallel" or "simultaneously" when launching multiple agents at once

## 5. User Interaction

**AskUserQuestion - Get user input:**

````markdown
After gathering behaviors, use AskUserQuestion tool to let user select:

```json
{
  "questions": [{
    "question": "Which rules would you like to enable?",
    "header": "Configure",
    "multiSelect": true,
    "options": [...]
  }]
}
```
````

**Best practices:**
- State timing: "After gathering...", "Before creating..."
- Provide complete JSON structure
- Use for: confirmations, selections, gathering missing info

## 6. External Data

**WebFetch - Read documentation:**
```markdown
Use WebFetch tool to read the official docs: https://docs.example.com
```

**WebSearch - Find current information:**

```markdown
Use WebSearch tool to verify current package versions before installation.
```

## 7. Agent Tools Configuration

**Minimal necessary tools in frontmatter:**

```yaml
# Read-only agent
tools: ["Read", "Grep", "Glob"]

# File-creating agent
tools: ["Write", "Read"]

# Complex workflow agent
tools: ["Glob", "Grep", "Read", "WebFetch", "TodoWrite", "WebSearch"]
```

**Best practices:**

- List minimal necessary tools
- Use array syntax: `["Tool1", "Tool2"]` or `Tool1, Tool2`
- Follow principle of least privilege

## Summary: Tool Invocation Rules

**1. Core File Operations (Read, Write, Glob, Grep, Edit):**
   - **Do NOT explicitly call** - describe actions directly
   - ✅ "Find all hookify rule files matching pattern..."
   - ✅ "Read the file and extract frontmatter..."
   - ✅ "Create `agents/[identifier].md` with..."
   - ❌ "Use Glob tool to find..." / "Use Read tool to read..."

**2. Bash Tool:**
   - **Do NOT say "Use Bash tool"** - describe commands directly
   - ✅ "Run `git diff --name-only` to see modified files"
   - ✅ "Check git status to identify changed files"
   - ✅ "Create a pull request using `gh pr create`"
   - ✅ Special case: Use the pattern &#33;&#96;command&#96; for inline execution in commands
   - ❌ "Use Bash tool to stage files with `git add`"

**3. Task Tool (Launch Agents):**
   - **Most cases**: Describe agent launch directly
   - ✅ "Launch 2-3 code-explorer agents in parallel"
   - ✅ "Use a Haiku agent to check if the pull request exists"
   - ✅ "Launch all agents simultaneously: code-reviewer, pr-test-analyzer"
   - ✅ Only use "Use Task tool" when providing full JSON structure for general-purpose agents
   - ❌ "Use Task tool to launch code-reviewer agent" (when descriptive is sufficient)

**4. Skill Tool:**
   - **Always explicitly call** - "Load X skill using the Skill tool"
   - ✅ "**FIRST: Load the hookify:writing-rules skill** using the Skill tool"
   - ✅ "**Load the [skill-name] skill** to access specialized knowledge"
   - Use emphasis (bold/uppercase) for critical/first-time skill loading

**5. Other Tools (TodoWrite, AskUserQuestion, WebFetch, WebSearch):**
   - Explicit invocation helpful for clarity
   - ✅ "**Use TodoWrite tool** to track progress"
   - ✅ "Use WebFetch tool to read the official docs"

## General Principles

- **Be Procedural**: Use numbered steps or bullet points with clear actions
- **Be Specific**: Describe what should be done and what should be returned
- **Use Emphasis**: Bold/uppercase for critical/first-time usage
- **Provide Structure**: Include code blocks for patterns, JSON for complex calls

This approach makes commands more concise, saves tokens, and Claude can automatically infer the correct tools from context.

## Anti-Pattern Examples

### Bad Examples (Don't do this)

```markdown
# Command with explicit tool calls
Use the Glob tool to find all plugin files.
Use the Read tool to read each file.
Use the Grep tool to search for patterns.
Use the Bash tool to run git status.
Use the Task tool to launch the validator agent.
```

### Good Examples (Do this)

```markdown
# Command with descriptive actions
Find all plugin files matching the pattern `**/*.md`.
Read each file and extract the frontmatter.
Search for explicit tool invocation patterns.
Run `git status` to check for changes.
Launch the validator agent to check compliance.
```

## Context-Specific Patterns

### In Commands

Commands should describe actions, not tool usage:

```markdown
---
description: Optimize plugin structure
allowed-tools: [Read, Glob, Grep, AskUserQuestion]
---

# Plugin Optimization Workflow

1. Find all component files in the plugin directory
2. Read each file and validate frontmatter
3. Search for explicit tool invocation anti-patterns
4. After analysis, use AskUserQuestion tool to confirm fixes
5. Generate optimization report
```

### In Agent System Prompts

Agents should receive clear procedural instructions:

```markdown
You are a plugin validator.

**Validation Process:**

1. Scan the plugin directory for all component files
2. Read each component and extract metadata
3. Check for missing required fields
4. Search for anti-patterns like explicit tool calls
5. Compile findings into categorized report

**Use TodoWrite tool** to track validation progress.
**Load the plugin-best-practices skill** for validation standards.
```

### In Skills

Skills provide knowledge, not direct tool instructions:

```markdown
# Validation Workflow

To validate a plugin:

1. Scan directory structure for standard component locations
2. For each component file:
   - Extract YAML frontmatter
   - Validate required fields
   - Check content patterns
3. Compile issues by severity
4. Generate actionable fix suggestions

Reference `scripts/validate-frontmatter.sh` for automated checks.
```

## Detection Patterns

When validating plugins, check for these anti-patterns:

### Explicit Core Tool Calls

```markdown
# Anti-patterns to detect:
- "Use Read tool"
- "Use Write tool"
- "Use Glob tool"
- "Use Grep tool"
- "Use Edit tool"

# These should be rewritten descriptively
```

### Explicit Bash Tool Calls

```markdown
# Anti-patterns to detect:
- "Use Bash tool to"
- "Use the Bash tool"
- "Call Bash tool"

# Exceptions (allowed):
- Inline execution: pattern &#33;&#96;command&#96; (exclamation mark + backtick + command + backtick)
- allowed-tools config: Bash(git:*)
```

### Unnecessary Task Tool Mentions

```markdown
# Anti-patterns to detect:
- "Use Task tool to launch [specific-agent]"
- "Call Task tool to run [plugin-agent]"

# Allowed:
- "Use Task tool to launch..." with full JSON structure
- Descriptive: "Launch [agent-name] agent"
```

## Validation Script Hints

When creating validation scripts, detect these patterns:

```bash
# Detect explicit tool calls
grep -E "(Use|Call) (Read|Write|Glob|Grep|Edit) tool" commands/*.md agents/*.md

# Detect explicit Bash calls (excluding allowed patterns)
grep -E "Use (the )?Bash tool" commands/*.md | grep -v "Bash(.*:.*)"

# Detect unnecessary Task tool mentions
grep -E "Use Task tool to launch (code-|api-|test-)" commands/*.md
```

These patterns help identify files that need optimization to follow official standards.
