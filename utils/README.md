# Utils Plugin

Utility commands for day-to-day automation.

## Overview

The Utils Plugin provides helpful utility commands for everyday development workflows. These commands streamline common tasks and improve productivity during development sessions.

## Commands

### `/utils:continue`

Resumes the previous conversation or task without restating context.

**Metadata:**

| Field | Value |
|-------|-------|
| Description | Resume the previous conversation or task without restating context |

**What it does:**
1. Continues the previous conversation from where it left off
2. Uses existing context without repeating prior information
3. Asks for clarification only if essential details are missing
4. Maintains conversation flow seamlessly

**Usage:**
```bash
/utils:continue
```

**Example workflow:**
```bash
# Start a task
# ... conversation develops ...
# Need to continue later or after interruption

/utils:continue

# Claude will:
# - Continue from where we left off
# - Use all previous context
# - Not repeat prior information
# - Ask only if critical details missing
```

**Features:**
- Seamless conversation continuation
- Context preservation
- No redundant information
- Smart clarification requests

**When to use:**
- After interruption during a task
- When resuming work from previous session
- When continuing a complex multi-step task
- After clarifying a misunderstanding

---

### `/utils:create-command`

Creates new command templates for Claude Code plugins.

**Metadata:**

| Field | Value |
|-------|-------|
| Allowed Tools | `Task`, `Write`, `Bash(mkdir:*)` |
| Argument Hint | `[Project\|Personal] [description of what the command should do]` |

**What it does:**
1. Guides you through creating a new command
2. Generates command template with proper structure
3. Includes frontmatter with required fields
4. Provides example usage and documentation
5. Creates command file in appropriate location

**Command Scopes:**
- **Project commands** — Stored in `.claude/commands/` and committed to source control
- **Personal commands** — Stored in `~/.claude/commands/` for individual reuse

**Core Features:**
- Organize commands with directory namespacing
- Support dynamic arguments through `$ARGUMENTS`, `$1`, `$2`, etc.
- Run bash setup commands with the `!` prefix
- Reference files and folders via the `@` prefix
- Include extended thinking keywords when deeper reasoning is required
- Configure metadata through frontmatter

**Frontmatter Options:**
- **`allowed-tools`** — Declare permitted tools (e.g. `Bash(git add:*)`, `Write`)
- **`argument-hint`** — Provide autocomplete hints (e.g. `[Project|Personal] [description]`)
- **`description`** — Summarize the command intent
- **`model`** — Pick the Claude model (`claude-haiku-4-5-20251001`, `claude-sonnet-4-5-20250929`, `claude-opus-4-1-20250805`)

**Argument Handling:**
- `$ARGUMENTS` captures the full argument string, e.g. `/fix-issue 123 high-priority`
- `$1`, `$2`, `$3` capture individual positions, e.g. `/review-pr 456 high alice`

**Usage:**
```bash
/utils:create-command
```

**Example workflows:**
```bash
# Create a new command
/utils:create-command Review pull request with security focus
/utils:create-command Project Generate API documentation from code
/utils:create-command Personal Optimize database performance analysis
/utils:create-command Project Create comprehensive unit tests
```

**Command template includes:**
- Frontmatter with metadata (allowed-tools, description, etc.)
- Context section (git status, project state)
- Requirements section
- Task description
- Example usage
- Workflow guidance

**Example Templates:**

**Bash Command with Git Operations:**
```markdown
---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
description: Create a git commit
---

## Context
- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task
Based on the above changes, create a single git commit.
```

**File References:**
```markdown
---
description: Review code implementation
---

# Reference a specific file
Review the implementation in @src/utils/helpers.js

# Reference multiple files
Compare @src/old-version.js with @src/new-version.js
```

**Positional Arguments:**
```markdown
---
argument-hint: [pr-number] [priority] [assignee]
description: Review pull request
---

Review PR #$1 with priority $2 and assign to $3.
Focus on security, performance, and code style.
```

## Installation

This plugin is included in the Claude Code repository. The commands are automatically available when using Claude Code.

## Best Practices

### Using `/utils:continue`
- Use when resuming work after interruption
- Use for complex tasks that span multiple sessions
- Use when context is clear and you want to continue
- Don't use if you need to restart with different context
- Trust Claude to maintain context appropriately

### Using `/utils:create-command`
- Use when adding new commands to plugins
- Provide clear command name and description
- Think about allowed tools before creating
- Consider command arguments and usage patterns
- Review generated template and customize as needed

## Workflow Integration

### Task Continuation Workflow:
```bash
# Start complex task
# ... work on task ...
# Need to pause or interrupted

/utils:continue

# Task continues seamlessly
```

### Command Creation Workflow:
```bash
# Need new command for plugin
/utils:create-command

# Follow interactive prompts
# Review generated template
# Customize as needed
# Save to appropriate plugin directory
```

## Requirements

- Claude Code installed
- For `/utils:create-command`: Understanding of Claude Code command structure
- For `/utils:continue`: Previous conversation context

## Troubleshooting

### `/utils:continue` loses context

**Issue**: Command doesn't remember previous context

**Solution**:
- Ensure you're in the same conversation
- Context is maintained within session
- May need to provide context if session changed
- Re-state key details if needed

### `/utils:create-command` generates wrong template

**Issue**: Template doesn't match your needs

**Solution**:
- Customize generated template after creation
- Provide more specific guidance during creation
- Modify frontmatter as needed
- Adjust task description to your requirements

## Tips

- **Use /utils:continue frequently**: Maintains smooth workflow during interruptions
- **Be specific with /utils:create-command**: Clear guidance produces better templates
- **Review templates**: Always review and customize generated templates
- **Iterate on commands**: Refine commands based on usage
- **Share commands**: Well-designed commands can be reused

## Author

Frad LEE (fradser@gmail.com)

## Version

1.0.0
