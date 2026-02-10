# Commands Component Reference

> **Modern Approach**: For new plugins, prefer using **Skills** over Commands. Skills provide better modularity, are self-contained, and support progressive disclosure patterns. Commands are primarily for backward compatibility and simple user-invoked operations. See `./references/components/skills.md` for the recommended approach.

Plugins add custom slash commands that integrate seamlessly with Claude Code's command system.

**Location**: `commands/` directory in plugin root

**File format**: Markdown files with YAML frontmatter + Markdown body

---

## Command Structure

### Frontmatter (YAML)

Use phase-based instruction skill structure for command-style logic.

**Required Fields**:
- `description`: Short description shown in command list
- `argument-hint`: Usage pattern for arguments (use `<>` for required, `[]` for optional). MUST be empty or omitted if command takes no arguments (do not use placeholder text like `(no arguments - provides reference guidance)`).

**Optional Fields**:
- `allowed-tools`: Array of tools Claude can use (see `./references/tool-invocations.md` for syntax)
- `disable-model-invocation`: Set `true` for commands that only execute scripts without LLM

### Body (Markdown)

Write **directives FOR Claude** (instructions), not descriptions to users.

Use phase-based structure for execution logic.

## Integration Points

- Commands appear in `/help` and autocomplete
- Invoked via `/command-name [arguments]`
- Access to all Claude Code tools (unless restricted by `allowed-tools`)
- Can launch plugin agents and invoke skills
- User's working directory is preserved

## Best Practices

### Should Do
- **Use `allowed-tools`**: Restrict tool access (principle of least privilege) via `allowed-tools` frontmatter.
- **Dynamic Context**: Use inline bash backticks to inject dynamic context into prompts.

### Must Do
- **Write Instructions FOR Claude**: Write prompts as directives _to_ the agent (e.g., "Review this code...") rather than descriptions _to_ the user.
- **Use YAML Frontmatter**: Include `description` and `argument-hint` in your `.md` files.
- **Validate Arguments**: Check for required arguments inside the prompt logic and handle missing inputs gracefully.

### Avoid
- **Chatty Prompts**: Don't waste tokens explaining what you are going to do; just provide the instructions to do it.
- **Destructive Defaults**: Avoid running destructive bash commands (delete/overwrite) without explicit user confirmation steps or validation.
