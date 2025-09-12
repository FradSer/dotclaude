---
description: Create a custom slash command in .claude/commands
argument-hint: [description of what the command should do]
allowed-tools: Write, Bash(mkdir:*)
---

Create a new custom slash command in `.claude/commands/` directory following official Claude Code specifications.

## Task

Analyze the user's request from `$ARGUMENTS` and create a properly structured slash command following the Claude Code slash commands documentation.

## Custom Slash Commands Overview

Custom slash commands allow you to define frequently-used prompts as Markdown files that Claude Code can execute. Commands are organized by scope (project-specific or personal) and support namespacing through directory structures.

### Syntax
```
/<command-name> [arguments]
```

### Parameters
| Parameter        | Description                                                       |
| :--------------- | :---------------------------------------------------------------- |
| `<command-name>` | Name derived from the Markdown filename (without `.md` extension) |
| `[arguments]`    | Optional arguments passed to the command                          |

### Project Commands
Commands stored in your repository and shared with your team. When listed in `/help`, these commands show "(project)" after their description.

**Location**: `.claude/commands/`

## Features to Implement

### Arguments
Pass dynamic values to commands using argument placeholders:

**All arguments with `$ARGUMENTS`**:
The `$ARGUMENTS` placeholder captures all arguments passed to the command:
```bash
# Command definition
echo 'Fix issue #$ARGUMENTS following our coding standards' > .claude/commands/fix-issue.md

# Usage
> /fix-issue 123 high-priority
# $ARGUMENTS becomes: "123 high-priority"
```

**Individual arguments with `$1`, `$2`, etc.**:
Access specific arguments individually using positional parameters (similar to shell scripts):
```bash
# Command definition  
echo 'Review PR #$1 with priority $2 and assign to $3' > .claude/commands/review-pr.md

# Usage
> /review-pr 456 high alice
# $1 becomes "456", $2 becomes "high", $3 becomes "alice"
```

Use positional arguments when you need to:
* Access arguments individually in different parts of your command
* Provide defaults for missing arguments
* Build more structured commands with specific parameter roles

### Bash Command Execution
Execute bash commands before the slash command runs using the `!` prefix. The output is included in the command context. You *must* include `allowed-tools` with the `Bash` tool, but you can choose the specific bash commands to allow.

Example:
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
Include file contents in commands using the `@` prefix to reference files and directories.

Example:
```markdown
# Reference a specific file
Review the implementation in @src/utils/helpers.js

# Reference multiple files
Compare @src/old-version.js with @src/new-version.js
```

### Thinking Mode
Slash commands can trigger extended thinking by including extended thinking keywords.

### Namespacing
Organize commands in subdirectories. The subdirectories are used for organization and appear in the command description, but they do not affect the command name itself. The description will show whether the command comes from the project directory (`.claude/commands`) or the user-level directory (`~/.claude/commands`), along with the subdirectory name.

For example, a file at `.claude/commands/frontend/component.md` creates the command `/component` with description showing "(project:frontend)".

### Frontmatter
Command files support frontmatter, useful for specifying metadata about the command:

| Frontmatter     | Purpose                                                                                                                                                                               | Default                             |
| :-------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | :---------------------------------- |
| `allowed-tools` | List of tools the command can use                                                                                                                                                     | Inherits from the conversation      |
| `argument-hint` | The arguments expected for the slash command. Example: `argument-hint: add [tagId] \| remove [tagId] \| list`. This hint is shown to the user when auto-completing the slash command. | None                                |
| `description`   | Brief description of the command                                                                                                                                                      | Uses the first line from the prompt |
| `model`         | Specific model string                                                                                                                                                                 | Inherits from the conversation      |

## Command Creation Process

1. **Extract purpose**: Understand what the user wants the command to do from `$ARGUMENTS`
2. **Generate name**: Create a descriptive command name (lowercase with hyphens)
3. **Ensure directory**: Create `.claude/commands/` if it doesn't exist using `mkdir -p`
4. **Write command file**: Create the `.md` file with proper frontmatter and structure following all specifications above
5. **Include appropriate features**: Add argument handling, file references, bash execution, or thinking mode as needed

## Usage Examples

```
/create-command Review pull request with security focus
/create-command 生成API文档
/create-command Optimize database performance
/create-command Create unit tests for components
```

The created command will follow all Claude Code slash command best practices and official specifications.
