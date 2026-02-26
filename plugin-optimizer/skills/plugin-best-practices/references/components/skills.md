# Skills Component Reference

Plugins provide Agent Skills that extend Claude's capabilities. Skills are model-invoked—Claude autonomously decides when to use them based on task context.

Skills package domain expertise in a format agents can access and apply—turning general-purpose agents into knowledgeable specialists.

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

Only `name` and `description` are allowed for official best practices compliance. Additional fields are supported but may affect progressive disclosure alignment.

### Description Best Practices

The `description` field is **critical for skill discovery** - Claude uses it to select the right skill from potentially 100+ available skills.

**Requirements**:
| Requirement | Description |
|-------------|-------------|
| **Person** | Third-person only ("This skill should be used when...") |
| **Structure** | [What it does]. Use when [scenario 1], [scenario 2], or [user phrases]. |
| **Max Length** | 1024 characters |
| **Trigger Phrases** | Include specific user phrases like "validate plugin", "check frontmatter" |
| **Purpose** | Skill discovery - loaded during startup (~50 tokens) |

**Examples**:
```yaml
# Correct - third person with trigger phrases
description: This skill should be used when the user asks to "validate plugin structure", "review manifest files", "check frontmatter compliance", or needs guidance on Claude Code plugin architectural best practices.

# Correct - concise with scenarios
description: Reviews code for best practices and potential issues. Use when reviewing code, checking PRs, or analyzing code quality.

# Correct - functional description
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or automating document processing.

# Wrong - first person (NEVER use "I")
description: I can help you validate plugins...

# Wrong - second person (NEVER use "You")
description: You should use this when you want to validate...

# Wrong - too vague
description: A skill for plugin validation
```

**Why it matters**:
- **Skill selection**: Claude uses `description` to choose the right skill from 100+ options
- **Context efficiency**: Only metadata (name + description) loads at startup (~50 tokens)
- **Trigger accuracy**: Specific trigger phrases significantly improve skill activation rates (tested: 84% vs 20% without proper triggers)

| Field                    | Required    | Description                                                                                                                              |
| ------------------------ | ----------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| name                     | No          | Display name for the skill. If omitted, uses the directory name. Lowercase letters, numbers, and hyphens only (max 64 characters).      |
| argument-hint | No  | Hint shown during autocomplete to indicate expected arguments. Example: `[issue-number]` or `[filename] [format]`. MUST be empty or omitted if skill takes no arguments (do not use placeholder text like `(no arguments - provides reference guidance)`). |
| description              | Recommended | **Critical for skill discovery**. What the skill does and when to use it. MUST use third-person voice with specific trigger phrases. Max 1024 chars. See **Description Best Practices** below. |
| disable-model-invocation | No          | Set to `true` to prevent Claude from automatically loading this skill. Use for workflows triggered manually. Default: `false`. |
| user-invocable           | No          | Set to `false` to hide from the / menu. Use for background knowledge users shouldn't invoke directly. Default: `true`.                  |
| allowed-tools            | No          | Tools Claude can use without asking permission when this skill is active. See `./references/tool-invocations.md` for syntax.        |
| model                    | No          | Model to use when this skill is active: `sonnet`, `opus`, `haiku`, or `inherit`.                                                        |
| context                  | No          | Set to `fork` to run in a forked subagent context.                                                                                       |
| agent                    | No          | Which subagent type to use when `context: fork` is set: `Explore`, `Plan`, `general-purpose`, or custom agent name.                      |
| hooks                    | No          | Hooks scoped to this skill's lifecycle. See `./references/components/hooks.md` for configuration format.                                               |

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

Skills use progressive disclosure to protect the context window and enable composability.

**Three-Tier Token Budget**:

| Tier | Content | Token Budget | When Loaded |
|------|---------|--------------|-------------|
| Metadata | Name + description (frontmatter) | ~50 tokens | Always (skill discovery) |
| SKILL.md | Core instructions and navigation | ~500 tokens | When skill is invoked |
| References | Detailed documentation, examples | 2000+ tokens | MUST only access when specifically needed |

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
  - MUST only access when specifically needed

### Must Do
- Place `SKILL.md` inside a subdirectory (e.g., `skills/my-skill/SKILL.md`)
- Use imperative style in bodies ("Parse the file...", "Validate the input...")
- Write frontmatter descriptions in **third person** ("This skill should be used when...")
- Include **specific trigger phrases** in description (e.g., "Use when validating...", "when user asks to...")
- Keep description under **1024 characters** - concise but specific
- Keep main `SKILL.md` around 500 tokens with progressive disclosure to supporting files
- Each skill SHOULD have a single, well-defined responsibility
- Scripts MUST be executable with shebang and `${CLAUDE_PLUGIN_ROOT}` paths
- Reference supporting files from SKILL.md so Claude knows what they contain

### Instruction-Type Skill Structure
- MAY include pre-phase sections before "Phase 1":
  - **"## Initialization"**: Environment setup, prerequisites, configuration steps
  - **"## Background Knowledge"**: Domain knowledge, context, reference information

### Should Do
- Reference external documentation files rather than embedding all details
- Use `user-invocable: false` for agent-only skills and `context: fork` for complex analysis
- Use `disable-model-invocation: true` for workflows with side effects you want to control timing

### Avoid
- Exceeding ~500 tokens in SKILL.md (indicates poor design—refactor)
- Duplicating information between `SKILL.md` and reference files
- Combining multiple unrelated capabilities into a single skill

### Scripts as Tools

Skills can include scripts that act as self-documenting, modifiable tools.

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

## Skill Complexity Levels

| Level | Tokens | Characteristics | Example |
|-------|--------|-----------------|---------|
| Simple | ~200 | Templates, formatting, single-purpose | Status report writer |
| Intermediate | ~500–800 | Data retrieval, file processing, multi-tool coordination | Financial model builder |
| Complex | 1000–2500 | Multi-step pipelines, external tool orchestration | Bioinformatics analysis pipeline |

When complexity exceeds intermediate, consider splitting into multiple focused skills.

## Skills in the Agent Architecture

| Layer | Purpose | Examples |
|-------|---------|----------|
| Agent loop | Core reasoning and decision-making | Claude's built-in capabilities |
| Agent runtime | Execution environment | Bash, filesystem, code execution |
| MCP servers | External tool and data connections | Database access, API integrations |
| Skills library | Domain expertise and workflows | Coding standards, deployment procedures |

**Skills + MCP Integration**: Skills and MCP servers work together naturally. A skill might coordinate:
- Web search for current information
- Internal databases via MCP
- Slack/Notion for team context
- File operations for output generation