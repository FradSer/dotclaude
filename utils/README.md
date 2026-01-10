# Utils Plugin

Utility commands for day-to-day automation.

## Overview

The Utils Plugin provides helpful utility commands for everyday development workflows. These commands streamline common tasks and improve productivity during development sessions.

## Commands

### `/continue`

Resumes the previous conversation or task without restating context.

**What it does:**
1. Continues the previous conversation from where it left off
2. Uses existing context without repeating prior information
3. Asks for clarification only if essential details are missing
4. Maintains conversation flow seamlessly

**Usage:**
```bash
/continue
```

**Example workflow:**
```bash
# Start a task
# ... conversation develops ...
# Need to continue later or after interruption

/continue

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

### `/create-command`

Creates new command templates for Claude Code plugins.

**What it does:**
1. Guides you through creating a new command
2. Generates command template with proper structure
3. Includes frontmatter with required fields
4. Provides example usage and documentation
5. Creates command file in appropriate location

**Usage:**
```bash
/create-command
```

**Example workflow:**
```bash
# Create a new command
/create-command

# Claude will ask:
# - Command name
# - Command description
# - Allowed tools
# - Arguments (if any)
# - Task description
# - Example usage

# Then generates command template
```

**Features:**
- Interactive command creation
- Proper template structure
- Frontmatter generation
- Example usage included
- Documentation guidance

**Command template includes:**
- Frontmatter with metadata (allowed-tools, description, etc.)
- Context section (git status, project state)
- Requirements section
- Task description
- Example usage
- Workflow guidance

## Installation

This plugin is included in the Claude Code repository. The commands are automatically available when using Claude Code.

## Best Practices

### Using `/continue`
- Use when resuming work after interruption
- Use for complex tasks that span multiple sessions
- Use when context is clear and you want to continue
- Don't use if you need to restart with different context
- Trust Claude to maintain context appropriately

### Using `/create-command`
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

/continue

# Task continues seamlessly
```

### Command Creation Workflow:
```bash
# Need new command for plugin
/create-command

# Follow interactive prompts
# Review generated template
# Customize as needed
# Save to appropriate plugin directory
```

## Requirements

- Claude Code installed
- For `/create-command`: Understanding of Claude Code command structure
- For `/continue`: Previous conversation context

## Troubleshooting

### `/continue` loses context

**Issue**: Command doesn't remember previous context

**Solution**:
- Ensure you're in the same conversation
- Context is maintained within session
- May need to provide context if session changed
- Re-state key details if needed

### `/create-command` generates wrong template

**Issue**: Template doesn't match your needs

**Solution**:
- Customize generated template after creation
- Provide more specific guidance during creation
- Modify frontmatter as needed
- Adjust task description to your requirements

## Tips

- **Use /continue frequently**: Maintains smooth workflow during interruptions
- **Be specific with /create-command**: Clear guidance produces better templates
- **Review templates**: Always review and customize generated templates
- **Iterate on commands**: Refine commands based on usage
- **Share commands**: Well-designed commands can be reused

## Author

Frad LEE (fradser@gmail.com)

## Version

1.0.0
