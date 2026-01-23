# Skills Component Reference

Plugins can provide Agent Skills that extend Claude's capabilities. Skills are model-invoked—Claude autonomously decides when to use them based on the task context.

**Location**: `skills/` directory in plugin root

**File format**: Directories containing `SKILL.md` files with YAML frontmatter and markdown content

## Skill structure

```
skills/
└── my-skill/
    ├── SKILL.md          (required - main instructions)
    ├── reference.md      (optional - detailed docs)
    ├── examples.md       (optional - usage examples)
    └── scripts/          (optional - executable logic)
        └── helper.py
```

## Frontmatter fields

All fields are optional. Only `description` is recommended so Claude knows when to use the skill.

```yaml
---
name: my-skill
description: What this skill does and when to use it
argument-hint: [filename] [format]
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Grep
model: sonnet
context: fork
agent: Explore
hooks:
  PreToolUse: [...]
---
```

| Field                    | Required    | Description                                                                                                                              |
| ------------------------ | ----------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| name                     | No          | Display name for the skill. If omitted, uses the directory name. Lowercase letters, numbers, and hyphens only (max 64 characters).      |
| description              | Recommended | What the skill does and when to use it. Claude uses this to decide when to apply the skill.                                            |
| argument-hint            | No          | Hint shown during autocomplete to indicate expected arguments. Example: `[issue-number]` or `[filename] [format]`.                      |
| disable-model-invocation | No          | Set to `true` to prevent Claude from automatically loading this skill. Use for workflows you want to trigger manually. Default: `false`. |
| user-invocable           | No          | Set to `false` to hide from the / menu. Use for background knowledge users shouldn't invoke directly. Default: `true`.                  |
| allowed-tools            | No          | Tools Claude can use without asking permission when this skill is active.                                                                |
| model                    | No          | Model to use when this skill is active: `sonnet`, `opus`, `haiku`, or `inherit`.                                                        |
| context                  | No          | Set to `fork` to run in a forked subagent context.                                                                                       |
| agent                    | No          | Which subagent type to use when `context: fork` is set: `Explore`, `Plan`, `general-purpose`, or custom agent name.                      |
| hooks                    | No          | Hooks scoped to this skill's lifecycle. See Hooks documentation for configuration format.                                               |

## String substitutions

Skills support string substitution for dynamic values:

| Variable               | Description                                                                                                                              |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| $ARGUMENTS             | All arguments passed when invoking the skill. If not present in content, arguments are appended as `ARGUMENTS: <value>`.                 |
| ${CLAUDE_SESSION_ID}   | The current session ID. Useful for logging, creating session-specific files, or correlating skill output with sessions.                 |

## Integration behavior

* Plugin Skills are automatically discovered when the plugin is installed
* Claude autonomously invokes Skills based on matching task context
* Skills can include supporting files alongside SKILL.md
* Reference supporting files from SKILL.md so Claude knows what each file contains and when to load it

**Note**: There is a known limitation where plugin skills may not appear in the slash command menu, even though project-level skills do. See [GitHub issue #17271](https://github.com/anthropics/claude-code/issues/17271#issuecomment-3785693359) for details.

## Best Practices

### Golden Rule: < 500 Lines

Keep `SKILL.md` under 500 lines. Move detailed reference material to separate files. If exceeded, refactor by:
1. Splitting into multiple focused atomic skills
2. Moving detailed logic to reference files (progressive disclosure)
3. Using external scripts or tools for complex operations

### Progressive Disclosure Strategy

Use a two-level approach:
- **Level 1 (Skill Definition)**: Tell the agent "what I can do" - overview and navigation
  - Frontmatter with third-person description
  - Core purpose and usage scenarios
  - Quick reference to detailed documentation
  - Basic workflow overview using imperative style
- **Level 2 (Detailed Documentation)**: Reference external files for complex logic
  - Reference supporting files from SKILL.md: `For complete API details, see reference.md`
  - Use code interpreter scripts for complex operations
  - Don't make the LLM "read" thousands of lines of rules

### Must Do
- Place `SKILL.md` inside a subdirectory (e.g., `skills/my-skill/SKILL.md`)
- Use imperative style in bodies ("Parse the file...", "Validate the input...")
- Write frontmatter descriptions in third person ("This skill should be used when...")
- Keep main `SKILL.md` under 500 lines with progressive disclosure
- Each skill should have a single, well-defined responsibility
- Scripts must be executable with shebang and `${CLAUDE_PLUGIN_ROOT}` paths
- Reference supporting files from SKILL.md so Claude knows what they contain

### Should Do
- Reference external documentation files rather than embedding all details
- Use `user-invocable: false` for agent-only skills and `context: fork` for complex analysis
- Use `disable-model-invocation: true` for workflows with side effects you want to control timing

### Avoid
- Exceeding 500 lines (indicates poor design—refactor)
- Duplicating information between `SKILL.md` and reference files
- Combining multiple unrelated capabilities into a single skill
