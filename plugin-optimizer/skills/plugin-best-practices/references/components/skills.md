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

## Declaring in plugin.json

Declare by frontmatter (see `user-invocable` and `disable-model-invocation` fields above):
- **Knowledge-type** (`user-invocable: false`) → `plugin.json` **`skills`** field
- **Instruction-type** (default or `user-invocable: true`) → **`commands`** field
- **`disable-model-invocation: true`** → **`commands`** (still instruction-type; prevents Claude auto-invoke)

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
- Each skill SHOULD have a single, well-defined responsibility
- Scripts MUST be executable with shebang and `${CLAUDE_PLUGIN_ROOT}` paths
- Reference supporting files from SKILL.md so Claude knows what they contain

### Should Do
- Reference external documentation files rather than embedding all details
- Use `user-invocable: false` for agent-only skills and `context: fork` for complex analysis
- Use `disable-model-invocation: true` for workflows with side effects you want to control timing

### Avoid
- Exceeding 500 lines (indicates poor design—refactor)
- Duplicating information between `SKILL.md` and reference files
- Combining multiple unrelated capabilities into a single skill

## Text Structure Patterns

### Instruction-Type vs Knowledge-Type Structure

| Aspect | Instruction-Type (user-invocable) | Knowledge-Type (agent-only) |
|--------|-----------------------------------|------------------------------|
| **Opening** | "You are the [Role]..." (2nd person) | "[What this does]..." (declarative) |
| **Sections** | Linear workflow (Phase 1-7) | Topic-based chapters |
| **Instructions** | Specific operations: "Use Glob to find...", "Run bash..." | Validation rules: "Verify skills are < 500 lines" |
| **Density** | High: 3-4 levels of detail | Low: Single-line rules + external references |
| **Examples** | Inline commands & output templates | Standard YAML templates |
| **Navigation** | Vertical single-file reading | Radial multi-file with references/ |

### Writing Style Guidelines

#### Instruction-Type Style
```markdown
# Task Name

You are the Orchestrator. Execute these phases sequentially.

## Phase 1: Discovery

**Goal**: Validate structure and detect issues.

**Actions**:
1. **Resolution**: Use `realpath` to resolve the absolute path...
2. **Validation**: Ensure the resolved path exists.
3. **Execute Scripts**:
   - Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh "$TARGET"`
   - Analyze output for failures

**Output**: Comprehensive list of issues found
```

**Characteristics**:
- Second person commands: "You will...", "Use...", "Ensure..."
- Executable specifics: tool names, commands, paths
- Multi-level detail expansion (3-4 levels deep)
- Self-contained: all details inline

#### Knowledge-Type Style
```markdown
# Standards Reference

Validate plugins against official standards.

## Key Rules

**Critical Checks**:
- Verify skills are < 500 lines with progressive disclosure
- Verify agents include 2-4 `<example>` blocks
- Check components use kebab-case naming
- Validate no explicit tool invocations

**Severity Levels**:
- **Critical**: MUST fix before plugin works
- **Warning**: SHOULD fix for best practices
- **Info**: MAY improve (optional)

## Detailed References

See `references/components/agents.md` for agent specifications.
See `references/manifest-schema.md` for plugin.json details.
```

**Characteristics**:
- Imperative rules: "Verify", "Check", "Ensure" (no "You")
- High-level standards with external references
- Single-line rules (1-2 levels deep)
- Navigation layer: points to detailed docs

### Content Organization Rules

**Instruction-Type MUST**:
- Include all execution details inline (< 300 lines total)
- Use numbered phases/steps for sequential workflows
- Provide complete commands with variables: `bash $SCRIPT "$ARG"`
- Include output format templates

**Knowledge-Type MUST**:
- Keep SKILL.md under 200 lines as navigation layer
- Move detailed content to `references/[topic].md`
- Use bullet lists for quick scanning
- Reference external docs: "See `references/X.md` for..."

### Writing Pattern Examples

#### Same Concept, Two Styles

**Validation Requirement**: Agent must have required frontmatter fields

**Instruction-Type Expression**:
```markdown
**Actions**:
4. **Validate Agent Frontmatter**:
   - Use Read to open `agents/*.md` files
   - Extract YAML between `---` markers
   - Verify required fields:
     - `name`: 3-50 chars, kebab-case
     - `description`: Must contain 2-4 `<example>` blocks
     - `model`: Must be inherit|sonnet|opus|haiku
     - `color`: Must be blue|cyan|green|yellow|magenta|red
   - Add missing fields to error list
```

**Knowledge-Type Expression**:
```markdown
**Critical Checks**:
- Verify agents have clear descriptions for delegation
- Verify agents include 2-4 `<example>` blocks in description

See `references/components/agents.md` for complete frontmatter specification.
```

### Decision Guide

**Use Instruction-Type when**:
- Task requires precise execution order
- User invokes via slash command
- Workflow is < 300 lines total
- Need to specify exact commands/tools

**Use Knowledge-Type when**:
- Providing standards/best practices
- Content exceeds 500 lines
- Agent-only reference (not user-facing)
- Content requires frequent updates

**Anti-Pattern Warning**:
```markdown
# DON'T: Mix styles
You are an expert. Verify agents are valid.  # ← Confusing: 2nd person + imperative

# DO: Pick one style
You are an expert. Validate all agents...     # ← Instruction-type
Verify agents have required fields...         # ← Knowledge-type
```

### Prompt Repetition Best Practices

- Repeat critical rules, MUST/SHOULD requirements, or safety constraints naturally within workflow phases
- Use concise restatement rather than verbatim duplication
- Focus on essentials: only repeat information critical for correct execution
