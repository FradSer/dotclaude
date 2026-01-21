# Best Practices for Creating Claude Code Plugins

Based on the official documentation and architectural patterns, here is the comprehensive guide to creating high-quality Claude Code plugins.

**Key Insights from Official Plugins:**

- Plugin manifests (`.claude-plugin/plugin.json`) are intentionally minimal - rely on auto-discovery
- Commands use `allowed-tools` for security (e.g., `Bash(gh:*)` for GitHub-only operations)
- Agents include 2-4 `<example>` blocks in descriptions showing triggering scenarios
- Skills use `SKILL.md` inside subdirectories with supporting `references/`, `examples/`, and `scripts/` folders
- Complex workflows use parallel agent execution with confidence-based filtering (see code-review)

## 1. Plugin Structure & Organization

**Must Do**

- **Follow Standard Layout:** Place components in the root directories: `commands/`, `agents/`, `skills/`, and `hooks/`.
- **Place Manifest Correctly:** Ensure `plugin.json` is located in the `.claude-plugin/` directory.
- **Use Portable Paths:** Always use `${CLAUDE_PLUGIN_ROOT}` environment variable for file references. Never use hardcoded absolute paths or relative paths assuming a working directory.
- **Use Kebab-Case:** Name all directories and files using `kebab-case` (e.g., `code-review.md`, `api-testing/`).

**Should Do**

- **Rely on Auto-Discovery:** Keep `plugin.json` lean by letting Claude discover components automatically rather than manually listing every file.
- **Group Complex Components:** Use subdirectories for organization when you have 15+ items (e.g., `commands/ci/build.md`), though note this requires custom path configuration in `plugin.json`.
- **Include READMEs:** Place a README in the plugin root and distinct READMEs in script subdirectories explaining dependencies.

**Avoid**

- **Nesting Components in Config:** Do not put commands or agents inside the `.claude-plugin/` directory.
- **Generic Names:** Avoid names like `utils`, `misc`, or `temp`. Be descriptive (`date-utils`, `pdf-processing`).

### Plugin Manifest Patterns (plugin.json)

**Location:** `.claude-plugin/plugin.json`

**Core Pattern (Minimal - Recommended):**

```json
{
  "name": "plugin-name",
  "description": "Brief description of what the plugin does",
  "author": {
    "name": "Author Name",
    "email": "author@example.com"
  }
}
```

**Required Fields:**
- `name`: Plugin identifier (kebab-case, matches directory name)
- `description`: One-line summary of plugin functionality
- `author`: Object with at least `name` field

**Optional Fields:**
- `version`: Semantic version string (e.g., "0.1.0", "1.2.3")
- `author.email`: Author email address
- `author.url`: Author website URL
- `homepage`: Plugin homepage/documentation URL
- `repository`: Repository URL (GitHub, GitLab, etc.)
- `license`: License identifier (e.g., "MIT", "Apache-2.0")
- `keywords`: Array of searchable keywords (e.g., `["git", "automation", "workflow"]`)

**Key Insights:**
- **Keep it minimal**: Official plugins intentionally use minimal manifests - rely on auto-discovery
- **Auto-discovery works**: Claude automatically discovers `commands/`, `agents/`, `skills/`, and `hooks/` directories
- **No component listing**: Do not manually list commands, agents, or skills in `plugin.json`
- **External plugins may be verbose**: Third-party plugins (like Stripe) may include more metadata for marketplace visibility

**Examples from Official Plugins:**

```json
// Minimal (most common pattern)
{
  "name": "code-review",
  "description": "Automated code review for pull requests using multiple specialized agents",
  "author": {
    "name": "Anthropic",
    "email": "support@anthropic.com"
  }
}

// With version and homepage
{
  "name": "stripe",
  "description": "Stripe development plugin for Claude",
  "version": "0.1.0",
  "author": {
    "name": "Stripe",
    "url": "https://stripe.com"
  },
  "homepage": "https://docs.stripe.com",
  "repository": "https://github.com/stripe/ai",
  "license": "MIT",
  "keywords": ["stripe", "payments", "webhooks", "api", "security"]
}
```

### Marketplace Manifest Patterns (marketplace.json)

**Location:** `.claude-plugin/marketplace.json`

**Core Pattern:**

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "marketplace-name",
  "description": "Description of the plugin marketplace",
  "owner": {
    "name": "Owner Name",
    "email": "owner@example.com"
  },
  "plugins": [
    {
      "name": "plugin-name",
      "description": "Plugin description",
      "source": "./plugin-directory",
      "version": "0.1.0",
      "author": {
        "name": "Author Name",
        "email": "author@example.com"
      },
      "category": "development",
      "homepage": "https://github.com/owner/repo/tree/main/plugin-directory"
    }
  ]
}
```

**Top-Level Fields:**
- `$schema`: Schema URL for validation (required)
- `name`: Marketplace identifier
- `description`: Marketplace description
- `owner`: Object with `name` and `email` (required)
- `plugins`: Array of plugin definitions (required)

**Plugin Object Fields:**

**Required:**
- `name`: Plugin identifier (must match plugin directory name)
- `description`: Plugin description
- `source`: Plugin location - can be:
  - String path: `"./plugin-directory"` (relative to marketplace.json)
  - Object: `{"source": "url", "url": "https://github.com/owner/repo.git"}` (for external Git repos)

**Optional:**
- `version`: Semantic version string
- `author`: Object with `name` and optional `email`
- `category`: Category identifier (e.g., "development", "productivity", "security", "testing", "database", "design", "monitoring", "deployment", "learning")
- `homepage`: Plugin homepage/documentation URL
- `strict`: Boolean (default: false) - whether plugin requires strict mode
- `lspServers`: Object defining Language Server Protocol configurations (for LSP plugins)
- `tags`: Array of tags (e.g., `["community-managed"]`)

**Source Field Patterns:**

```json
// Local plugin (relative path)
"source": "./plugins/my-plugin"

// External plugin (Git repository)
"source": {
  "source": "url",
  "url": "https://github.com/owner/repo.git"
}
```

**Category Values (from official marketplace):**
- `development`: Development tools, LSP servers, code intelligence
- `productivity`: Workflow automation, project management, collaboration
- `security`: Security scanning, vulnerability detection
- `testing`: Testing frameworks, browser automation
- `database`: Database integrations, data management
- `design`: Design tools, UI/UX integration
- `monitoring`: Error tracking, observability
- `deployment`: Deployment platforms, CI/CD
- `learning`: Educational tools, learning modes

**LSP Server Configuration Pattern:**

```json
{
  "name": "typescript-lsp",
  "source": "./plugins/typescript-lsp",
  "lspServers": {
    "typescript": {
      "command": "typescript-language-server",
      "args": ["--stdio"],
      "extensionToLanguage": {
        ".ts": "typescript",
        ".tsx": "typescriptreact",
        ".js": "javascript",
        ".jsx": "javascriptreact"
      }
    }
  }
}
```

**Key Insights:**
- **Schema validation**: Always include `$schema` for IDE validation
- **Relative paths**: Use `"./plugin-name"` for local plugins relative to marketplace.json location
- **External repos**: Use object syntax with `source: "url"` for Git repository sources
- **Categories**: Use standard categories for better discoverability
- **Versioning**: Include version numbers for tracking plugin updates
- **Homepage links**: Provide GitHub/documentation links for user reference

## 2. Command Development

**Must Do**

- **Write Instructions FOR Claude:** Write prompts as directives _to_ the agent (e.g., "Review this code for...") rather than descriptions _to_ the user (e.g., "This command reviews code...").
- **Use YAML Frontmatter:** Include `description` and `argument-hint` in your `.md` files.
- **Validate Arguments:** Check for required arguments (`$1`, `$2`) inside the prompt logic and handle missing inputs gracefully.

**Should Do**

- **Use Argument Hints:** Define `argument-hint: [arg1] [arg2]` to help users with autocomplete.
- **Limit Tool Access:** Use the `allowed-tools` field to adhere to the principle of least privilege.
- **Prevent Recursion:** Use `disable-model-invocation: true` if your command is purely for user interaction and shouldn't be called autonomously by other agents/skills.
- **Integrate Bash for Dynamic Context:** Use inline bash execution with the correct syntax `` !`command` `` (backticks required) to gather context dynamically before Claude processes the prompt.

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

Current git status: !`git status`
Current branch: !`git branch --show-current`
Recent commits: !`git log --oneline -10`

# WRONG - Missing backticks

Current git status: !git status
```

The backticks `` ` `` are **required syntax** - they mark the boundaries of the bash command to be executed. The output is captured and embedded into the prompt context before Claude processes it.

**Avoid**

- **Chatty Prompts:** Don't waste tokens explaining what you are going to do; just provide the instructions to do it.
- **Destructive Defaults:** Avoid running destructive bash commands (delete/overwrite) without explicit user confirmation steps or validation.

## 3. Agent Design

**Must Do**

- **Define Triggering Examples:** In the `description` field, you **must** include 2-4 `<example>` blocks showing Context, User input, and Assistant response. This is critical for the router to select your agent.
- **Use Second Person:** Write system prompts addressing the agent directly ("You are an expert...", "Your responsibilities are...").
- **Define Output Format:** Clearly specify exactly how the agent should structure its final response.

**Should Do**

- **Inherit Model:** Use `model: inherit` unless you specifically require the capabilities of Opus or the speed of Haiku.
- **Define Permission Mode:** Use `permissionMode` (e.g., `permissionMode: acceptEdits` for trusted refactoring agents) to streamline user interaction, but default to `permissionMode: default` for safety.
- **Explicitly Control Tools:** Use the `tools` (allowlist) or `disallowedTools` (denylist) fields in frontmatter to strictly define agent capabilities.
- **Use Color Coding:** Assign distinct colors (`blue`, `green`, `red`, etc.) to visually distinguish agents in the UI.
- **Structure Prompts:** Follow the pattern: Role → Core Responsibilities → Analysis Process → Quality Standards → Output Format → Edge Cases.

**Avoid**

- **First Person Prompts:** Never write "I am an agent..." in the system prompt.
- **Vague Triggers:** Avoid generic descriptions like "Helps with code." Be specific: "Use this agent when the user asks to refactor a React component."

## 4. Skill Implementation

**Must Do**

- **Use Imperative Style:** Write SKILL.md bodies using verb-first instructions ("Parse the file...", "Validate the input...") rather than second person ("You should...").
- **Third-Person Descriptions:** Write frontmatter descriptions in the third person with specific trigger phrases ("This skill should be used when the user asks to...").
- **Structure Correctly:** Place the `SKILL.md` file inside a subdirectory (e.g., `skills/my-skill/SKILL.md`).

**Should Do**

- **Manage Visibility:** Use `user-invocable: false` for utility skills that should only be called by agents, not directly by users via slash commands.
- **Isolate Context:** Use `context: fork` in frontmatter for skills that perform complex analysis or side tasks, preserving the main conversation context.
- **Progressive Disclosure:** Keep `SKILL.md` lean (1,500-2,000 words). Move detailed documentation to `references/` and code to `examples/` or `scripts/`.
- **Bundle Resources:** Include static assets (templates, schemas) in `assets/` and executable utilities in `scripts/`.
- **Reference Resources:** Explicitly mention the existence of your reference files and scripts in the main `SKILL.md` so Claude knows they exist.

**Avoid**

- **Monolithic Files:** Don't dump 5,000+ words into `SKILL.md`. It bloats the context window.
- **Duplication:** Do not repeat information between `SKILL.md` and `references/` files.

## 5. Hook Usage

**Must Do**

- **Validate Inputs:** In bash hooks, strictly validate all JSON inputs and sanitize variables to prevent injection attacks.
- **Quote Variables:** Always quote bash variables (e.g., `"$CLAUDE_PROJECT_DIR"`) to handle spaces in paths correctly.
- **Return Valid JSON:** Ensure your hooks output valid JSON structures for decisions (`allow`/`deny`) and messages.

**Should Do**

- **Use Prompt Hooks for Logic:** Use `type: "prompt"` (LLM-based) for complex, context-aware decisions (e.g., "Is this code safe?").
- **Use Command Hooks for Speed:** Use `type: "command"` (Bash-based) for deterministic, fast checks (e.g., linting, file existence).
- **Set Timeouts:** Define explicit `timeout` values (default is 60s for commands, 30s for prompts).

**Avoid**

- **Blocking Errors:** Avoid returning exit code `2` (Blocking Error) unless the operation is critical and must be stopped. Use exit code `1` (Non-blocking) or `0` (Success) for warnings.
- **Modifying Global State:** Avoid hooks that change the environment unexpectedly, as they run in parallel and order is not guaranteed.

## 6. TodoWrite Tool Usage Standards

**When to Use TodoWrite:**

- **3+ Distinct Steps:** Only create todo lists for tasks with 3 or more distinct, meaningful steps
- **Complex Multi-Component Work:** Plugin development involving multiple files (commands + agents + skills)
- **Sequential Dependencies:** When later steps depend on earlier step completion
- **User Visibility:** When users need to track progress of multi-step operations

**Must Do**

- **Dual Form Naming:** Every task requires both `content` (imperative: "Run tests") and `activeForm` (continuous: "Running tests")
- **Real-time Updates:** Mark tasks `in_progress` BEFORE starting work, `completed` IMMEDIATELY after finishing
- **Single Active Task:** Maintain exactly ONE task as `in_progress` at any time
- **Honest Status:** NEVER mark incomplete tasks as `completed` - if blocked or failed, keep as `in_progress` and create new task for resolution

**When NOT to Use TodoWrite:**

- **Simple Tasks:** Single-file edits, trivial changes, 1-2 step operations
- **Research Only:** Pure exploration, reading files, searching codebase
- **Conversational:** Answering questions, explaining concepts

**Example - Plugin Creation (3+ steps, USE TodoWrite):**

```json
[
  {
    "content": "Create plugin manifest and directory structure",
    "activeForm": "Creating plugin manifest and directory structure",
    "status": "in_progress"
  },
  {
    "content": "Implement command with frontmatter and validation",
    "activeForm": "Implementing command with frontmatter and validation",
    "status": "pending"
  },
  {
    "content": "Create agent with triggering examples",
    "activeForm": "Creating agent with triggering examples",
    "status": "pending"
  }
]
```

**Example - Single File Edit (DON'T use TodoWrite):**

- "Fix typo in README.md" → Just do it, no todo list needed

## 7. Tool Invocation Patterns (Official Standards)

### Core Principle

**Core File Operations tools (Read, Write, Glob, Grep, Edit) should NOT be explicitly called** - simply describe the action directly. Claude will automatically use the appropriate tool. For other tools (Bash, TodoWrite, Skill, Task, AskUserQuestion, WebFetch, WebSearch), explicit invocation may be helpful for clarity.

### 1. File Discovery & Reading

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

### 2. File Modification

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

### 3. Search & Execution

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

Current git status: !`git status`
Current branch: !`git branch --show-current`

# Instructions: Describe commands directly (do NOT say "Use Bash tool")

1. **Gather Context**: Run `git diff --name-only` to see modified files
2. Check git status to identify changed files
3. Create a pull request using `gh pr create`
4. Stage the relevant files with `git add`
```

**Best practices:**

- **Do NOT say "Use Bash tool"** - just describe the command directly
- **Inline execution syntax**: Use `!`command`` for dynamic context in commands (special case)
- **Direct command description**: "Run `git diff`", "Check git status", "Create PR with `gh pr create`"
- Claude will automatically use Bash tool when it sees a command

### 4. Workflow Orchestration

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

### 5. User Interaction

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

### 6. External Data

**WebFetch - Read documentation:**
```markdown
Use WebFetch tool to read the official docs: https://docs.example.com
```

**WebSearch - Find current information:**

```markdown
Use WebSearch tool to verify current package versions before installation.
```

### 7. Agent Tools Configuration

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

### Summary: Tool Invocation Rules

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
   - ✅ Special case: Use `!`command`` for inline execution in commands
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

**General Principles:**
- **Be Procedural**: Use numbered steps or bullet points with clear actions
- **Be Specific**: Describe what should be done and what should be returned
- **Use Emphasis**: Bold/uppercase for critical/first-time usage
- **Provide Structure**: Include code blocks for patterns, JSON for complex calls

This approach makes commands more concise, saves tokens, and Claude can automatically infer the correct tools from context.

## 8. General Tips

- **Security First:** Treat all inputs in hooks and commands as potentially untrusted.
- **Test with Debug:** Use `claude --debug` to see detailed logs of hook execution and agent routing.
- **Portability:** Ensure scripts work across different environments (macOS/Linux). Avoid system-specific tools unless documented as dependencies.
- **Version Control:** Use the `version` field in `plugin.json` and follow semantic versioning.
