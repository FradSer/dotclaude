# Claude Code Plugin File Patterns Analysis

This document summarizes the patterns and structure of various Markdown files in Claude Code plugins.

## Directory Structure

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── commands/                 # Command files (.md)
├── agents/                   # Agent files (.md)
├── skills/                   # Skill directories
│   └── skill-name/
│       ├── SKILL.md         # Skill main file (required)
│       ├── README.md        # Additional documentation (optional)
│       ├── references/      # Reference materials (optional)
│       ├── examples/        # Example files (optional)
│       └── scripts/         # Helper scripts (optional)
├── hooks/
│   └── hooks.json           # Hook configuration
├── .mcp.json                # MCP server configuration
├── examples/                # Plugin-level examples (optional)
└── README.md                # Plugin documentation
```

## 1. SKILL.md File Pattern

### Location
`skills/skill-name/SKILL.md`

### Frontmatter Structure

```yaml
---
name: skill-name                    # Required: Skill identifier
description: This skill should be used when...  # Required: Trigger condition description
version: 1.0.0                      # Optional: Version number
license: Complete terms in LICENSE.txt  # Optional: License information
---
```

### Content Structure

1. **Overview**
   - Purpose and core concepts of the skill
   - List of key concepts

2. **Detailed Instructions**
   - Structured guidance content
   - Organized in sections (using ##, ###)

3. **Best Practices**
   - DO/DON'T lists
   - Common patterns and anti-patterns

4. **Examples and References**
   - Links to examples/ and references/

### Key Characteristics

- **description field is critical**: Must clearly describe when to use the skill
- **Trigger phrases**: Include specific phrases users might say
- **Third-person description**: "This skill should be used when..."
- **Progressive disclosure**: Core content in SKILL.md, detailed information in references/

### Example

```markdown
---
name: frontend-design
description: Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when the user asks to build web components, pages, or applications. Generates creative, polished code that avoids generic AI aesthetics.
license: Complete terms in LICENSE.txt
---

This skill guides creation of distinctive, production-grade frontend interfaces...

## Design Thinking
...

## Frontend Aesthetics Guidelines
...
```

## 2. Agents File Pattern

### Location
`agents/agent-name.md`

### Frontmatter Structure

```yaml
---
name: agent-identifier              # Required: Agent identifier (3-50 chars, lowercase, hyphens)
description: Use this agent when... # Required: Trigger conditions and examples
model: inherit                      # Required: inherit/sonnet/opus/haiku
color: blue                         # Required: blue/cyan/green/yellow/magenta/red
tools: ["Read", "Write", "Grep"]   # Optional: Tool restriction list
---
```

### Description Format

Must include trigger conditions and `<example>` blocks:

```yaml
description: Use this agent when [conditions]. Examples:

<example>
Context: [Scenario description]
user: "[User message]"
assistant: "[How Claude should respond]"
<commentary>
[Why this agent should be triggered]
</commentary>
</example>

<example>
[More examples...]
</example>
```

### System Prompt Structure

Content after frontmatter becomes the agent's system prompt.

For complete system prompt structure patterns and examples, see **`references/agents.md`** (Section 3: Agent Design) which covers:
- System prompt template structure
- Role definition patterns
- Responsibility organization
- Quality standards specification
- Output format definition
- Edge case handling approaches

### Key Characteristics

- **name rules**: 3-50 characters, lowercase letters, numbers, hyphens, cannot start or end with hyphen
- **description must include examples**: 2-4 `<example>` blocks
- **System prompt uses second person**: "You are...", "You will..."
- **Structured output format**: Clearly defined output format

### Example

```markdown
---
name: code-reviewer
description: Use this agent when you need to review code for adherence to project guidelines...
model: opus
color: green
---

You are an expert code reviewer specializing in modern software development...

## Review Scope
...

## Core Review Responsibilities
...
```

## 3. Commands File Pattern

### Location
`commands/command-name.md`

### Frontmatter Structure

```yaml
---
description: "Short command description"                    # Required: Shown in /help
argument-hint: "<required> [optional]"        # Optional: Argument hints
allowed-tools: [Read, Glob, Grep, Bash]      # Optional: Allowed tools list
model: haiku                                  # Optional: Model override
hide-from-slash-command-tool: "true"         # Optional: Hide flag
---
```

### Content Structure

**Important**: Commands are instructions FOR Claude, not explanations FOR users.

```markdown
# Correct approach (instructions for Claude)
Review this code for security vulnerabilities including:
- SQL injection
- XSS attacks
- Authentication issues

Provide specific line numbers and severity ratings.

# Incorrect approach (messages to user)
This command will review your code for security issues.
You'll receive a report with vulnerability details.
```

### Dynamic Content

- `$ARGUMENTS` - User-provided arguments
- Pattern &#33;&#96;command&#96; (exclamation mark + backtick + command + backtick) - Execute bash commands to get context
- `${CLAUDE_PLUGIN_ROOT}` - Plugin root directory path

### Key Characteristics

- **Directive content**: Directly tells Claude what to do
- **Can use bash**: Execute commands via the pattern &#33;&#96;command&#96; to get context
- **Tool restrictions**: Reduce permission prompts via `allowed-tools`

### Example

```markdown
---
description: Create a git commit
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
---

## Context
# Format: &#33;&#96;command&#96; (exclamation mark + backtick + command + backtick)

- Current git status: &#33;&#96;git status&#96;
- Current git diff: &#33;&#96;git diff HEAD&#96;
- Current branch: &#33;&#96;git branch --show-current&#96;

## Your task

Based on the above changes, create a single git commit.
```

## 4. README.md File Pattern

### Location
Plugin root directory or skill subdirectory

### Structure

```markdown
# Plugin Name

Brief description of plugin purpose.

## Overview

What the plugin does and key features.

## Installation

How to install the plugin.

## Usage

How to use commands, agents, or skills.

## Structure

Directory layout explanation.

## Features

Detailed feature list.

## Examples

Usage examples.

## Contributing

How to contribute.

## License

License information.
```

### Key Characteristics

- **User-facing**: Unlike commands, README is for human readers
- **Complete documentation**: Includes installation, usage, examples, etc.
- **Clear structure**: Uses standard markdown headings for organization

## 5. Reference and Example File Patterns

### References Files
Location: `skills/skill-name/references/*.md`

- Detailed reference documentation
- In-depth technical explanations
- Patterns and best practices
- Usually longer (2000-4000 words)

### Examples Files
Location: `skills/skill-name/examples/*.md` or `examples/*.md`

- Complete working examples
- Directly usable code/configuration
- Commented explanations

### Scripts Files
Location: `skills/skill-name/scripts/*.sh` or `scripts/*.sh`

- Validation scripts
- Test scripts
- Utility scripts
- Executable helper programs

## 6. Hook Configuration File Pattern

### Location
`hooks/hooks.json`

### Structure

```json
{
  "hooks": [
    {
      "name": "hook-name",
      "event": "PreToolUse",
      "command": "${CLAUDE_PLUGIN_ROOT}/hooks/pretooluse.sh",
      "enabled": true
    }
  ]
}
```

### Hook Script Pattern

Can also use `.local.md` files to define hooks:

```yaml
---
name: warn-console-log
enabled: true
event: file
pattern: console\.log\(
action: warn
---

🔍 **Console.log detected**

You're adding a console.log statement. Please consider:
- Is this for debugging or should it be proper logging?
- Will this ship to production?
- Should this use a logging library instead?
```

## 7. MCP Configuration File Pattern

### Location
`.mcp.json` or `mcpServers` in `plugin.json`

### Structure

```json
{
  "server-name": {
    "type": "stdio",
    "command": "${CLAUDE_PLUGIN_ROOT}/scripts/server.sh",
    "env": {
      "API_KEY": "${API_KEY}"
    }
  }
}
```

## Naming Conventions

### File Naming
- **Lowercase letters and hyphens**: `agent-name.md`, `command-name.md`
- **SKILL.md fixed name**: Skill main file must be named `SKILL.md`
- **README.md fixed name**: Documentation files use `README.md`

### Directory Naming
- **kebab-case**: `skill-name/`, `agent-name/`
- **Plural form**: `commands/`, `agents/`, `skills/`, `hooks/`

## Best Practices Summary

### Frontmatter
- ✅ Use YAML frontmatter for configuration
- ✅ Required fields must be provided
- ✅ Optional fields only when needed
- ✅ Keep frontmatter concise

### Content Organization
- ✅ Use clear heading hierarchy (##, ###)
- ✅ Structured content (overview → details → examples)
- ✅ Progressive disclosure (core → references → examples)
- ✅ Include practical, usable examples

### Descriptions and Triggers
- ✅ Clear trigger conditions
- ✅ Include specific phrases and keywords
- ✅ Provide multiple examples (agents)
- ✅ Use third person (skills)

### Code and Examples
- ✅ Provide complete, runnable examples
- ✅ Include comments and explanations
- ✅ Demonstrate best practices
- ✅ Avoid outdated patterns

## File Type Comparison

| Type | Frontmatter | Content Audience | Primary Purpose | Required Fields |
|------|-------------|------------------|-----------------|--------------------|
| SKILL.md | name, description | Claude | Provide domain knowledge | name, description |
| Agent | name, description, model, color | Agent | Define agent behavior | name, description, model, color |
| Command | description | Claude | Execute user commands | description |
| README.md | None | Human | Documentation | None |
| Hook | name, event, command | Hook system | Event handling | name, event |

## Summary

These patterns demonstrate the standardized structure of Claude Code plugins:

1. **SKILL.md**: Provides domain knowledge and guidance, triggered via description
2. **Agents**: Autonomous subprocesses, triggered via example-rich descriptions
3. **Commands**: User-triggered instructions, direct instructions to Claude
4. **README.md**: Human-readable documentation
5. **References/Examples**: Detailed references and runnable examples

All files follow clear conventions ensuring plugin consistency and maintainability.
