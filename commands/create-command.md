---
description: Create a custom slash command following Claude Code specifications
argument-hint: [Project|Personal] [description of what the command should do]
allowed-tools: Task, Write, Bash(mkdir:*)
---

Create a new custom slash command in `.claude/commands/` directory following the official Claude Code slash commands specifications.

## Task

**IMPORTANT: You MUST use the Task tool to complete ALL tasks.**

Analyze the user's request from `$ARGUMENTS` and create a properly structured slash command that follows all Claude Code slash command requirements.

## Official Specifications Overview

Custom slash commands are Markdown files that define frequently-used prompts. Commands are organized by scope:

### Command Types

#### Project commands
Commands stored in your repository and shared with your team.
**Location**: `.claude/commands/`

#### Personal commands
Commands available across all your projects.
**Location**: `~/.claude/commands/`

### Features

- **Namespacing**: Organize commands in subdirectories
- **Dynamic arguments**: Use `$ARGUMENTS`, `$1`, `$2`, etc.
- **Bash execution**: Commands prefixed with ``!``
- **File references**: Files referenced with ``@``
- **Thinking mode**: Extended thinking keywords
- **Frontmatter**: Metadata configuration

## Frontmatter Options

Command files support frontmatter for specifying metadata:

**`allowed-tools`**
- Purpose: List of tools the command can use
- Example: `Bash(git add:*), Write`
- Default: Inherits from conversation

**`argument-hint`**
- Purpose: Arguments expected for auto-completion
- Example: `[Project|Personal] [description of what the command should do]`
- Default: None

**`description`**
- Purpose: Brief description of the command
- Example: `Review pull request`
- Default: Uses first line from prompt

**`model`**
- Purpose: Specific model to use
- Options: `claude-3-5-haiku-latest` (simple tasks), `claude-sonnet-4-0` (default), `claude-opus-4-1` (complex tasks, requires user confirmation)
- Default: `claude-sonnet-4-0`

## Argument Handling

### All arguments with `$ARGUMENTS`
```markdown
Fix issue #$ARGUMENTS following our coding standards
```
Usage: `/fix-issue 123 high-priority` → `$ARGUMENTS` becomes "123 high-priority"

### Individual arguments with `$1`, `$2`, etc.
```markdown
Review PR #$1 with priority $2 and assign to $3
```
Usage: `/review-pr 456 high alice` → `$1`="456", `$2`="high", `$3`="alice"

## Bash Command Execution

Execute bash commands before the slash command runs using the ``!`` prefix. The output is included in the command context. You *must* include `allowed-tools` with the `Bash` tool, but you can choose the specific bash commands to allow.

## File References

Include file contents in commands using the `@` prefix to reference files and directories.

## Thinking Mode

Slash commands can trigger extended thinking by including extended thinking keywords.

## Namespacing

Organize commands in subdirectories. The subdirectories are used for organization and appear in the command description, but they do not affect the command name itself.

For example:
- `.claude/commands/frontend/component.md` → `/component` (project:frontend)

## Command Creation Process

1. **Determine scope**: Extract first argument (Project/Personal, defaults to Project if not specified)
2. **Extract purpose**: Understand what the user wants from remaining `$ARGUMENTS`
3. **Generate name**: Create descriptive name (lowercase with hyphens)
4. **Create directory**: Create appropriate commands directory structure
5. **Write command file**: Include proper frontmatter and structure
6. **Add features**: Arguments, bash commands, file references as needed

## Usage Examples

```bash
/create-command Review pull request with security focus
/create-command Project Generate API documentation from code
/create-command Personal Optimize database performance analysis
/create-command Project Create comprehensive unit tests
```

The created command will follow all Claude Code slash command specifications and best practices.

## Complete Examples

### Bash Command with Git Operations

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

### File References

```markdown
---
description: Review code implementation
---

# Reference a specific file
Review the implementation in @src/utils/helpers.js

# Reference multiple files
Compare @src/old-version.js with @src/new-version.js
```

### Positional Arguments

```markdown
---
argument-hint: [pr-number] [priority] [assignee]
description: Review pull request
---

Review PR #$1 with priority $2 and assign to $3.
Focus on security, performance, and code style.
```
