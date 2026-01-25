---
name: plugin-best-practices
description: This skill should be used when the user asks to "validate a plugin", "optimize plugin", "check plugin quality", "review plugin structure", "find plugin issues", "check best practices", "analyze plugin", or mentions plugin validation, optimization, or quality assurance.
argument-hint: (no arguments - provides knowledge only)
user-invocable: false
version: 0.2.0
---

# Plugin Best Practices

Validate and optimize Claude Code plugins against official standards.

Use only "MUST", "MUST NOT", "SHOULD", "SHOULD NOT", and "MAY" as defined in RFC 2119. Replace REQUIRED/SHALL with MUST, SHALL NOT with MUST NOT, RECOMMENDED with SHOULD, NOT RECOMMENDED with SHOULD NOT, and OPTIONAL with MAY. See `references/rfc-2119.md`.

## Key Validation Rules

**Architecture Guidance**:
- **Prefer Skills over Commands**: Skills are the modern, recommended approach for extending Claude's capabilities. Use Skills for new plugins instead of Commands.

## Skills vs Agents: Core Distinctions

Understanding when to use Skills versus Agents is critical for plugin architecture.

### Skills: Reusable Capabilities

**Definition**: Skills are markdown files containing prompts that extend Claude's knowledge or provide workflow instructions. They run in the main conversation context.

**Two Types**:

1. **Instruction-Type Skills** (`user-invocable: true` → `commands`)
   - **Purpose**: Execute tasks when user invokes via `/command`
   - **Writing Style**: Imperative voice — "Load...", "Create...", "Analyze..."
   - **Structure**: Linear workflow with phases/steps
   - **Example**: `/optimize-plugin`, `/commit`, `/create-pr`

2. **Knowledge-Type Skills** (`user-invocable: false` → `skills`)
   - **Purpose**: Provide background knowledge for agents and main conversation
   - **Writing Style**: Declarative voice — "Commands are...", "Skills provide...", "Use when..."
   - **Structure**: Topic-based sections with concepts and rules
   - **Example**: `plugin-best-practices`, `git-conventions`

### Agents: Autonomous Specialists

**Definition**: Agents are independent subprocesses with their own system prompts, running in isolated context. They are experts with judgment and autonomy.

**Writing Style**: Descriptive and enabling
- **Not**: Step-by-step instructions (like instruction-type skills)
- **But**: Descriptions of responsibilities, capabilities, and approach
- **Voice**: Second person ("You are..."), describing what the agent CAN do, not commanding what it MUST do
- **Autonomy**: Agent decides HOW to accomplish goals based on its expertise

**Key Characteristics**:
- **Isolated Context**: Separate conversation history from main session
- **System Prompt**: Defined in agent `.md` file (after frontmatter)
- **Tool Restrictions**: Can have specific tool allowlist
- **Specialized Expertise**: Focused on single domain (security review, code simplification, etc.)
- **Router-Friendly**: Includes 2-4 `<example>` blocks in description for automatic delegation

### Comparison Table

| Aspect | Instruction-Type Skill | Knowledge-Type Skill | Agent |
|--------|----------------------|---------------------|-------|
| **Invocation** | User via `/command` | Auto-loaded by agents | Claude delegates tasks |
| **Context** | Main conversation | Main conversation | Isolated subprocess |
| **Voice** | Imperative ("Load...") | Declarative ("Skills are...") | Descriptive ("You are an expert...") |
| **Purpose** | Execute workflow | Provide knowledge | Autonomous specialist |
| **Structure** | Phase/step workflow | Topic sections | Responsibilities + Approach |
| **Autonomy** | Follows instructions | N/A (passive knowledge) | Makes expert decisions |
| **Tools** | Inherits from session | N/A | Restricted allowlist |
| **Length** | Any length | < 200 lines + refs | Concise (focused domain) |

### When to Use Each

**Use Instruction-Type Skill When**:
- User needs to invoke a workflow manually via slash command
- Workflow is linear with clear phases or steps
- Context should stay in main conversation (not isolated)
- Example patterns: `/execute-workflow`, `/process-input`, `/generate-output`

**Use Knowledge-Type Skill When**:
- Providing reference knowledge for agents or main conversation
- Content is documentation, standards, patterns, or concepts
- Claude should auto-load for relevant tasks
- Example patterns: `domain-best-practices`, `format-specifications`, `validation-rules`

**Use Agent When**:
- Task requires isolated context (separate conversation history)
- Need specialized system prompt with specific expertise persona
- Tool access needs restrictions for safety or focus
- Task benefits from autonomous expert decisions with judgment
- Example patterns: `domain-reviewer` agent, `format-validator` agent, `content-analyzer` agent

### Writing Style Examples

**Instruction-Type Skill** (imperative, directive):
```markdown
## Phase 1: Preparation
**Actions**:
1. Gather required input from user or context
2. Load necessary knowledge skills using Skill tool
3. Validate preconditions are met
4. Proceed to execution phase

## Phase 2: Execution
**Actions**:
1. Process input according to workflow logic
2. Apply transformations or generate outputs
3. Handle errors and edge cases
4. Collect results for reporting
```

**Knowledge-Type Skill** (declarative, informative):
```markdown
## Core Concepts
Components are modular units that extend Claude's capabilities.

**Component Types**:
- Commands — User-invocable workflows triggered via slash commands
- Agents — Autonomous specialists running in isolated context
- Skills — Reusable prompts providing instructions or knowledge
- Hooks — Event handlers responding to tool calls or lifecycle events

**Best Practices**:
- Components MUST follow naming conventions (kebab-case)
- Components SHOULD have clear, single responsibilities
- Components MAY reference other components using qualified names
```

**Agent** (descriptive, enabling):
```markdown
You are an expert [domain] specialist for [context].

## Core Responsibilities
1. **Analyze [inputs]** to understand requirements and constraints
2. **Apply [expertise]** based on domain knowledge and best practices
3. **Generate [outputs]** meeting quality and completeness criteria
4. **Collaborate with users** via AskUserQuestion for subjective decisions

## Knowledge Base
The loaded `[plugin-name]:[skill-name]` skill provides:
- [Domain] standards and validation rules
- Reference documentation for [specific areas]
- [Tool/pattern] guidelines and examples

Consult appropriate references when addressing each category of work.

## Approach
- **[Principle 1]**: [Description of how agent works]
- **[Principle 2]**: [Another key working principle]
- **Autonomous**: Make decisions based on expertise; consult user for subjective matters
- **Comprehensive**: Track all actions and results for reporting
```

**Skills and plugin.json declaration**:

| Config | User invocable | Claude invocable | Declare in |
|--------|----------------|------------------|------------|
| `user-invocable: false` | No | Yes | `skills` (knowledge-type) |
| (default) or `user-invocable: true` | Yes | Yes | `commands` (instruction-type) |
| `disable-model-invocation: true` | Yes | No | `commands` (instruction-type, no auto-invoke) |

- **Knowledge-type** (`user-invocable: false`) → `skills`: Agent-only knowledge; not in / menu. Use declarative style: "Commands are...", "Skills provide...".
- **Instruction-type** (default/`user-invocable: true`) → `commands`: User-invokable via /. Use imperative style: "Load...", "Create...", "Analyze...".
- **`disable-model-invocation: true`** → `commands`: User-only; prevents Claude auto-invoke (interactive config, side effects, recursion prevention).

**Critical Checks**:
- Verify skills are < 500 lines with progressive disclosure
- Verify agents have clear descriptions for automatic delegation and single responsibility
- Verify agents include 2-4 `<example>` blocks in description (critical for router)
- Check components use kebab-case naming
- Ensure scripts are executable with shebang and `${CLAUDE_PLUGIN_ROOT}` paths
- Validate no explicit tool invocations (see `references/tool-invocations.md` for patterns)
- **Verify skill references use qualified names**: Use `plugin-name:skill-name` format, not bare `skill-name`
- Use AskUserQuestion tool when user confirmation is needed
- Confirm all paths are relative and start with `./`
- Verify components are at plugin root, not inside `.claude-plugin/`
- Confirm skills/commands explicitly declared in plugin.json (recommended)
- **Verify skill type vs manifest**: `user-invocable: false` → `skills`; `user-invocable: true` (or default) → `commands`.
- **Verify skill writing style matches type**:
  - **Instruction-type** (`commands`): Use imperative voice ("Load...", "Create...", "Analyze...")
  - **Knowledge-type** (`skills`): Use declarative voice ("Commands are...", "Skills provide...")

**Severity Levels**:
- **Critical**: MUST fix before plugin works correctly
- **Warning**: SHOULD fix for best practices compliance
- **Info**: MAY improve (optional improvements)

## Additional Resources

Load detailed validation patterns from `references/` directory:
- **Components**: `references/components/[type].md` - Validate or create specific components (commands, agents, skills, hooks, mcp-servers, lsp-servers)
- **Structure**: `references/directory-structure.md` - Validate directory layout, file locations, naming conventions
- **Manifest**: `references/manifest-schema.md` - Validate or create plugin.json schema and configuration
- **Tool Usage**: `references/tool-invocations.md` - Check tool invocation patterns in component instructions
- **MCP Patterns**: `references/mcp-patterns.md` - MCP server integration patterns and best practices
- **Debugging**: `references/debugging.md` - Diagnose plugin loading failures, component discovery issues, hook/MCP problems
- **CLI Commands**: `references/cli-commands.md` - Use CLI commands for plugin management
- **TodoWrite Tool**: `references/todowrite-usage.md` - Use TodoWrite tool in plugin components

## Skill Writing Styles

Skills fall into two categories with distinct text structures:

### Instruction-Type Skills
**Config**: `user-invocable: true` (default) → declared in `commands`
**Purpose**: Execute tasks when invoked (e.g., `/command-name`)
**Style**: Imperative sentences — "Load the skill", "Analyze requirements", "Present results"

**Example snippet**:
```markdown
## Phase 1: Setup
**Actions**:
1. Gather required inputs and context
2. Load relevant knowledge skills using Skill tool
3. Validate prerequisites are met
4. Get user confirmation before proceeding
```

### Knowledge-Type Skills
**Config**: `user-invocable: false` → declared in `skills`
**Purpose**: Provide background knowledge for agents (e.g., `domain-standards`)
**Style**: Declarative sentences — "Commands are...", "Skills provide...", "Use when..."

**Example snippet**:
```markdown
## Component Basics
Components are modular extensions to Claude's functionality.

**Component Locations**:
- Project: `.claude/[type]/` — shared with team via version control
- Personal: `~/.claude/[type]/` — available across all projects
- Plugin: `plugin-name/[type]/` — bundled and distributed with plugin
```

### Quick Comparison

| Aspect | Instruction-Type | Knowledge-Type |
|--------|-----------------|----------------|
| Voice | Imperative ("Load...") | Declarative ("Skills are...") |
| Purpose | Direct actions | Teach concepts |
| Structure | Linear workflow | Topic-based sections |
| Length | Any length | < 200 lines + references/ |

See `references/components/skills.md` for detailed guidance.

### Prompt Repetition Best Practices

- Repeat critical rules, MUST/SHOULD requirements, or safety constraints naturally within workflow phases
- Use concise restatement rather than verbatim duplication
- Focus on essentials: only repeat information critical for correct execution

## Pattern References

For complete pattern templates and examples, see:
- **Skill patterns**: `references/components/skills.md` (structure, frontmatter, text styles)
- **Agent patterns**: `references/components/agents.md` (frontmatter, examples, hooks)
- **Skill references**: Always use qualified names (`plugin-name:skill-name`) in skill loads and agent frontmatter

### Parallel Agent Execution

Launch multiple agents simultaneously when tasks are independent to improve efficiency.

**Request Parallel Execution**:

```markdown
# Explicit parallel request

Launch all agents simultaneously:
- `domain-analyzer` agent
- `quality-validator` agent
- `format-checker` agent

# Or use "in parallel" phrasing

Launch 3 parallel agents to process different aspects independently
```

**Best Practices**:
- **Explicitly mention "parallel" or "simultaneously"** when launching multiple agents
- **Use descriptive style**: "Launch domain-analyzer agent"
- **Consolidate results**: Merge findings and resolve conflicts after parallel execution

**Common Pattern**:

```markdown
1. Sequential setup (if needed)
2. Launch specialized analyses in parallel:
   - `aspect-one-analyzer` agent — first dimension
   - `aspect-two-validator` agent — second dimension
   - `aspect-three-checker` agent — third dimension
3. Consolidate results and present unified output
```
