# Skills Component Reference

Plugins can provide Agent Skills that extend Claude's capabilities. Skills are model-invoked—Claude autonomously decides when to use them based on the task context.

Skills package domain expertise in a format agents can access and apply—turning general-purpose agents into knowledgeable specialists. The key insight: agents have intelligence and capabilities, but not always the expertise to effectively tackle real work. Skills bridge this gap.

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

Use these templates to align skill structure and voice with the correct type. See `${CLAUDE_PLUGIN_ROOT}/examples/instruction-skill.md` and `${CLAUDE_PLUGIN_ROOT}/examples/knowledge-skill.md` for complete templates.

| Field                    | Required    | Description                                                                                                                              |
| ------------------------ | ----------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| name                     | No          | Display name for the skill. If omitted, uses the directory name. Lowercase letters, numbers, and hyphens only (max 64 characters).      |
| description              | Recommended | What the skill does and when to use it. Claude uses this to decide when to apply the skill.                                            |
| argument-hint | No  | Hint shown during autocomplete to indicate expected arguments. Example: `[issue-number]` or `[filename] [format]`. MUST be empty or omitted if skill takes no arguments. |
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

### Golden Rule: ~500 Tokens for SKILL.md

Keep `SKILL.md` around 500 tokens (roughly 50-100 lines of typical content). Move detailed reference material to supporting files (same directory or `references/` subdirectory). If exceeded significantly, refactor by:
1. Splitting into multiple focused atomic skills
2. Moving detailed logic to reference files (progressive disclosure)
3. Using external scripts or tools for complex operations

### Progressive Disclosure Strategy

Skills use progressive disclosure to protect the context window and enable composability. At runtime, only metadata is shown initially—full content loads on demand.

**Three-Tier Token Budget**:

| Tier | Content | Token Budget | When Loaded |
|------|---------|--------------|-------------|
| Metadata | Name + description (frontmatter) | ~50 tokens | Always (skill discovery) |
| SKILL.md | Core instructions and navigation | ~500 tokens | When skill is invoked |
| References | Detailed documentation, examples | 2000+ tokens | MUST only access when specifically needed |

This approach means you can equip an agent with hundreds of skills without overwhelming its context window.

**Three-Level Implementation**:
- **Level 1 (Metadata)**: Tell the agent "when to use me"
  - Frontmatter with third-person description
  - Trigger phrases and use cases
  - ~50 tokens loaded during skill discovery
- **Level 2 (Skill Definition)**: Tell the agent "what I can do"
  - Core purpose and usage scenarios
  - Quick reference to detailed documentation
  - Basic workflow overview using imperative style
  - Target ~500 tokens
- **Level 3 (Detailed Documentation)**: Reference external files for complex logic
  - Reference supporting files from SKILL.md: `For complete API details, see reference.md`
  - Use code interpreter scripts for complex operations
  - Don't make the LLM "read" thousands of lines of rules
  - MUST only access when specifically needed

### Must Do
- Place `SKILL.md` inside a subdirectory (e.g., `skills/my-skill/SKILL.md`)
- Use imperative style in bodies ("Parse the file...", "Validate the input...")
- Write frontmatter descriptions in third person ("This skill should be used when...")
- Keep main `SKILL.md` around 500 tokens with progressive disclosure to supporting files
- Each skill SHOULD have a single, well-defined responsibility
- Scripts MUST be executable with shebang and `${CLAUDE_PLUGIN_ROOT}` paths
- Reference supporting files from SKILL.md so Claude knows what they contain

### Instruction-Type Skill Structure
- MAY include pre-phase sections before "Phase 1":
  - **"## Initialization"**: Environment setup, prerequisites, configuration steps
  - **"## Background Knowledge"**: Domain knowledge, context, reference information
- These sections provide foundational setup and context before entering the main workflow phases
- Use "## Initialization" when the workflow requires specific environment preparation
- Use "## Background Knowledge" when execution requires understanding of domain-specific concepts

### Should Do
- Reference external documentation files rather than embedding all details
- Use `user-invocable: false` for agent-only skills and `context: fork` for complex analysis
- Use `disable-model-invocation: true` for workflows with side effects you want to control timing

### Avoid
- Exceeding ~500 tokens in SKILL.md (indicates poor design—refactor)
- Duplicating information between `SKILL.md` and reference files
- Combining multiple unrelated capabilities into a single skill

### Scripts as Tools

Skills can include scripts that act as self-documenting, modifiable tools. Code is preferable to traditional tool definitions because:
- Code is self-documenting through its logic and comments
- The model can read, understand, and extend scripts as needed
- Scripts don't bloat the context window when not in use

**Script Design Pattern**:
```python
#!/usr/bin/env python3
# ${CLAUDE_PLUGIN_ROOT}/skills/my-skill/scripts/process_data.py
import sys

if len(sys.argv) != 2:
    print("USAGE: process_data.py <input_file>")
    sys.exit(1)

# Implementation details...
```

**Documentation Pattern** (in SKILL.md or reference file):
```markdown
## Data Processing
- Input validation: validate schema before processing
- Output format: JSON with standard fields

Use the `./scripts/process_data.py` script to process files in-place.
```

**Benefits**:
- Self-contained logic that can be tested independently
- Clear interface through argument handling
- Modifiable by the agent when workflows evolve
- Zero context cost until invoked

## Skill Complexity Levels

Skills range from simple documentation to sophisticated multi-step workflows. Design complexity appropriately:

| Level | Tokens | Characteristics | Example |
|-------|--------|-----------------|---------|
| Simple | ~200 | Templates, formatting, single-purpose | Status report writer |
| Intermediate | ~500–800 | Data retrieval, file processing, multi-tool coordination | Financial model builder |
| Complex | 1000–2500 | Multi-step pipelines, external tool orchestration | Bioinformatics analysis pipeline |

**Complexity Indicators**:
- **Simple**: Single file type, templating focus, minimal logic
- **Intermediate**: Multiple file operations, Python/script coordination, conditional logic
- **Complex**: External tool orchestration, multi-stage pipelines, extensive reference documentation

When complexity exceeds intermediate, consider splitting into multiple focused skills that compose together.

## Skills in the Agent Architecture

Skills fit into a complete agent architecture alongside other extension mechanisms:

| Layer | Purpose | Examples |
|-------|---------|----------|
| Agent loop | Core reasoning and decision-making | Claude's built-in capabilities |
| Agent runtime | Execution environment | Bash, filesystem, code execution |
| MCP servers | External tool and data connections | Database access, API integrations |
| Skills library | Domain expertise and workflows | Coding standards, deployment procedures |

Each layer has a clear purpose: the loop reasons, the runtime executes, MCP connects, and skills guide.

**Skills + MCP Integration**: Skills and MCP servers work together naturally. A skill might coordinate:
- Web search for current information
- Internal databases via MCP
- Slack/Notion for team context
- File operations for output generation

The skill provides the domain expertise for *how* to use these capabilities effectively.
