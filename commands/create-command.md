---
description: Create a custom slash command in .claude/commands
argument-hint: [description of what the command should do]
---

Create a new custom slash command in `.claude/commands/` directory following Claude Code specifications.

**Your task**: Analyze the user's request from `$ARGUMENTS` and create a properly structured slash command.

## Claude Code Slash Command Reference

### Custom Slash Commands
Custom slash commands are Markdown files that Claude Code can execute. Commands are organized by scope (project-specific or personal) and support namespacing through directory structures.

**Syntax**: `/<command-name> [arguments]`

**Project Commands Location**: `.claude/commands/` (shared with team, shows "(project)" in `/help`)

### Key Features

#### Arguments
**All arguments with `$ARGUMENTS`**:
```bash
echo 'Fix issue #$ARGUMENTS following our coding standards' > .claude/commands/fix-issue.md
# Usage: /fix-issue 123 high-priority
# $ARGUMENTS becomes: "123 high-priority"
```

**Individual arguments with `$1, $2, $3`**:
```bash
echo 'Review PR #$1 with priority $2 and assign to $3' > .claude/commands/review-pr.md
# Usage: /review-pr 456 high alice
# $1="456", $2="high", $3="alice"
```

#### File References
Include file contents using `@` prefix:
```markdown
Review the implementation in @src/utils/helpers.js
Compare @src/old-version.js with @src/new-version.js
```

#### Bash Command Execution
Execute bash commands using `!` prefix (requires `allowed-tools: Bash(command:*)`):
```markdown
---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
---

Current git status: !`git status`
Current branch: !`git branch --show-current`
```

#### Frontmatter Options
| Frontmatter     | Purpose                                                                                   | Default                        |
| :-------------- | :---------------------------------------------------------------------------------------- | :----------------------------- |
| `allowed-tools` | List of tools the command can use                                                         | Inherits from conversation     |
| `argument-hint` | Arguments expected for auto-completion. Example: `[pr-number] [priority] [assignee]`     | None                          |
| `description`   | Brief description of the command                                                          | Uses first line from prompt   |
| `model`         | Specific model string                                                                     | Inherits from conversation     |

#### Thinking Mode
Commands can trigger extended thinking by including extended thinking keywords.

#### Namespacing
Organize commands in subdirectories. Example: `.claude/commands/frontend/component.md` creates `/component` with "(project:frontend)" description.

## Command Creation Process

1. **Extract purpose**: Understand what the user wants the command to do
2. **Generate name**: Create a descriptive command name (lowercase with hyphens)
3. **Ensure directory**: Create `.claude/commands/` if it doesn't exist
4. **Write command**: Create the `.md` file with proper structure following above specifications

## Usage Examples

```
/create-command Review pull request with security focus
/create-command 生成API文档
/create-command Optimize database performance
/create-command Create unit tests for components
```

Your command will be created following all Claude Code slash command best practices and specifications.
