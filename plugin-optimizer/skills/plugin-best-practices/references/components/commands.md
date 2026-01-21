# Commands Component Reference

Plugins add custom slash commands that integrate seamlessly with Claude Code's command system.

**Location**: `commands/` directory in plugin root

**File format**: Markdown files with YAML frontmatter + Markdown body

---

## Command Structure

### Frontmatter (YAML)

```yaml
---
description: Brief description of what this command does
argument-hint: <required-arg> [optional-arg]
allowed-tools: ["Read", "Write", "Bash(git:*)"]  # Optional: restrict tool access
disable-model-invocation: true  # Optional: for user-only commands
---
```

**Required Fields**:
- `description`: Short description shown in command list
- `argument-hint`: Usage pattern for arguments (use `<>` for required, `[]` for optional)

**Optional Fields**:
- `allowed-tools`: Array of tools Claude can use (see tool-invocations.md for syntax)
- `disable-model-invocation`: Set `true` for commands that only execute scripts without LLM

### Body (Markdown)

Write **directives FOR Claude** (instructions), not descriptions to users.

**Structure Pattern**:
```markdown
# Command Title

Brief introduction of what Claude will do.

## Core Principles (Optional)
- Guiding principle 1
- Guiding principle 2

## Phase 1: Phase Name

**Goal**: What this phase accomplishes

**CRITICAL**: Important instruction or warning (Optional)

**Actions**:
1. Specific instruction 1
2. Specific instruction 2

If the user says "condition", do specific action.

## Phase 2: Next Phase
...
```

## Integration Points

- Commands appear in `/help` and autocomplete
- Invoked via `/command-name [arguments]`
- Access to all Claude Code tools (unless restricted by `allowed-tools`)
- Can launch plugin agents and invoke skills
- User's working directory is preserved

## Best Practices

### Should Do
- **Use `allowed-tools`**: Restrict tool access (principle of least privilege) via `allowed-tools` frontmatter.
- **Dynamic Context**: Use inline bash backticks (e.g., `` `!git status` ``) to inject dynamic context into prompts.

### Must Do
- **Write Instructions FOR Claude**: Write prompts as directives _to_ the agent (e.g., "Review this code...") rather than descriptions _to_ the user.
- **Use YAML Frontmatter**: Include `description` and `argument-hint` in your `.md` files.
- **Validate Arguments**: Check for required arguments inside the prompt logic and handle missing inputs gracefully.

### Avoid
- **Chatty Prompts**: Don't waste tokens explaining what you are going to do; just provide the instructions to do it.
- **Destructive Defaults**: Avoid running destructive bash commands (delete/overwrite) without explicit user confirmation steps or validation.
