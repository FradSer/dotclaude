---
name: plugin-best-practices
description: Validates Claude Code plugins against architectural best practices for Agents, Skills, MCP, and Progressive Disclosure. Use when validating plugin structure, reviewing manifest files, checking frontmatter compliance, or verifying tool invocation patterns.
---

# Plugin Validation & Best Practices

Validate Claude Code plugins against architectural standards. SKILL.md serves as a navigation guide; detailed content lives in `references/`.

## Quick Start

Run validation on a plugin:

```bash
python3 plugin-optimizer/scripts/validate-plugin.py <plugin-path>
```

For specific checks only:
```bash
python3 plugin-optimizer/scripts/validate-plugin.py <plugin-path> --check=manifest,frontmatter
```

## Component Selection Guide

| Component | When to Use | Key Requirements |
|-----------|-------------|------------------|
| **Instruction-type Skills** | User-invoked workflows, linear process | Imperative voice, phase-based, declared in `commands` |
| **Knowledge-type Skills** | Reference knowledge for agents | Declarative voice, topic-based, declared in `skills` |
| **Agents** | Isolated, specialized decision-making | Restricted tools, 2-4 `<example>` blocks, isolated context |
| **MCP Servers** | External tool/data integration | stdio/http/sse transport, ${CLAUDE_PLUGIN_ROOT} paths |
| **LSP Servers** | IDE features (go to definition) | Language server binary, extension mapping |
| **Hooks** | Event-driven automation | PreToolUse/PostToolUse events, command/prompt/agent types |

See `./references/component-model.md` for detailed selection criteria and `./references/components/` for implementation guides.

## Progressive Disclosure

Three-tier token structure ensures efficient context usage:

| Level | Content | Token Budget | Loading |
|-------|---------|--------------|---------|
| 1 | Metadata (name + description) | ~100 tokens | Always (at startup) |
| 2 | SKILL.md body | Under 5k tokens | When skill triggered |
| 3 | References/ files | Effectively unlimited | On-demand via bash |

**Implementation Pattern**:
- SKILL.md: Overview and navigation to reference files
- References/: Detailed specs, examples, patterns
- Scripts/: Executable utilities (no context cost until executed)

See `./references/component-model.md` for complete token budget guidelines.

## Validation Workflow

1. **Structure**: File patterns, directory layout, kebab-case naming
2. **Manifest**: plugin.json required fields and schema compliance
3. **Frontmatter**: YAML frontmatter in components, third-person descriptions
4. **Tool Invocations**: Anti-pattern detection (implicit vs explicit tool calls)
5. **Token Budget**: Progressive disclosure compliance (under 5k tokens for SKILL.md)

Run validation with `-v` flag for verbose output showing all passing checks.

See `./references/validation-checklist.md` for complete criteria.

## Requirement Levels (RFC 2119)

**MUST**: Absolute requirement - plugin will not function correctly without it
- Use `MUST` only, avoid `REQUIRED` or `SHALL`

**MUST NOT**: Absolute prohibition - behavior is forbidden
- Use `MUST NOT` only, avoid `SHALL NOT`

**SHOULD**: Recommended practice - valid reasons to ignore exist, but implications MUST be understood
- Use `SHOULD` only, avoid `RECOMMENDED`
- Consider security implications before choosing different course

**SHOULD NOT**: Discouraged but may be valid in specific circumstances
- Use `SHOULD NOT` only, avoid `NOT RECOMMENDED`
- Weigh full implications before implementing

**MAY**: Truly optional - vendor choice
- Use `MAY` only, avoid `OPTIONAL`
- Implementations without a feature MUST interoperate with those that include it

See `./references/rfc-2119.md` for complete RFC 2119 specification.

## Critical Patterns

### Tool Invocation Rules

| Tool | Style | Example |
|------|-------|---------|
| Read, Write, Edit, Glob, Grep | Implicit | "Find files matching..." |
| Bash | Implicit | "Run `git status`" |
| Task | Implicit | "Launch `plugin-name:agent-name` agent" |
| Skill | **Explicit** | "**Load `plugin-name:skill-name` skill** using the Skill tool" |
| TaskCreate | **Explicit** | "**Use TaskCreate tool** to track progress" |
| AskUserQuestion | **Explicit** | "Use `AskUserQuestion` tool to [action]" |

**Qualified names**: MUST use `plugin-name:component-name` format for plugin components.

**allowed-tools**: NEVER use bare `Bash` - always use filters like `Bash(git:*)`.

**Inline Bash**: Use ``!`command` `` (exclamation + backtick + command + backtick) for dynamic context.

See `./references/tool-invocations.md` for complete patterns and anti-patterns.

### Skill Frontmatter (Official Best Practices)

**Required fields**:
- `name`: Max 64 chars, lowercase letters/numbers/hyphens only
- `description`: Max 1024 chars, third-person voice, includes trigger phrases like "Use when..."

**Additional fields** are supported but affect progressive disclosure alignment.

### Agent Frontmatter

**Required fields**:
- `name`: 3-50 chars, kebab-case
- `model`: inherit, sonnet, opus, or haiku
- `color`: blue, cyan, green, yellow, magenta, or red
- **`<example>` blocks**: 2-4 required for router-friendliness

**CO-STAR Framework**:
- **C**ontext: Background info
- **O**bjective: What to achieve
- **S**tyle: Tone/Format
- **T**one: Attitude
- **A**udience: Who is this for?
- **R**esponse: Format of output

See `./references/components/agents.md` for complete agent design guidelines.

### Task Management

**Use TaskCreate for:**
- Tasks with 3+ distinct steps
- Multi-file/multi-component work
- Sequential dependencies

**Don't use TaskCreate for:**
- Single file edits
- 1-2 step operations
- Pure research/reading

**Core Requirements**:
- Dual form naming: subject ("Run tests") + activeForm ("Running tests")
- Real-time updates: mark `in_progress` BEFORE starting, `completed` AFTER finishing
- Single active task at any time
- Honest status: only mark `completed` when FULLY done

See `./references/task-management.md` for complete patterns and examples.

### MCP Server Configuration

**Transport Types:**
- **stdio**: Local CLI tools (git, docker, npm) - uses `command`, `args`, `env`
- **http**: Remote APIs (SaaS, cloud) - uses `url`, `headers`
- **sse**: Real-time streaming (monitoring, live updates) - uses `url`, `headers`

**Security:**
- NEVER hardcode secrets - always use `${ENV_VAR}` syntax
- Document required environment variables
- Provide `.env.example` template

See `./references/mcp-patterns.md` for complete MCP integration patterns.

### Frontmatter Requirements (Complete)

**Skill Frontmatter**:
- Required: `name` (max 64 chars, lowercase/hyphens), `description` (max 1024 chars, third-person)
- Optional: `argument-hint`, `allowed-tools`, `model`, `disable-model-invocation`, `user-invocable`, `context`, `agent`, `hooks`

**Agent Frontmatter**:
- Required: `name` (3-50 chars, kebab-case), `model`, `color`, 2-4 `<example>` blocks

**Command Frontmatter**:
- Required: `description`, `argument-hint` (MUST be empty/omitted if no arguments)
- Optional: `allowed-tools`, `disable-model-invocation`

See `./references/components/skills.md`, `./references/components/agents.md`, and `./references/components/commands.md` for complete frontmatter specifications.

## Directory Structure

**Standard Layout**:
```
plugin-name/
├── .claude-plugin/plugin.json    # Manifest (declare components here)
├── skills/                       # Agent Skills (RECOMMENDED)
│   └── skill-name/
│       ├── SKILL.md
│       └── references/
├── commands/                     # Legacy commands (optional)
├── agents/                       # Subagent definitions
├── hooks/hooks.json              # Hook configuration
├── .mcp.json                     # MCP server definitions
├── .lsp.json                     # LSP server configurations
└── scripts/                      # Executable scripts
```

**Critical Rules**:
- Components live at plugin root, NOT inside `.claude-plugin/`
- Scripts MUST be executable with shebangs
- Scripts MUST use `${CLAUDE_PLUGIN_ROOT}` for paths
- All paths MUST be relative and start with `./`

See `./references/directory-structure.md` for complete layout guidelines.

## Hook Configuration

**Available Events**:
- PreToolUse, PostToolUse, PostToolUseFailure
- PermissionRequest, UserPromptSubmit, Notification
- Stop, SubagentStart, SubagentStop
- SessionStart, SessionEnd, PreCompact

**Hook Types**:
- `command`: Execute shell commands or scripts
- `prompt`: Evaluate with LLM (uses `$ARGUMENTS` placeholder)
- `agent`: Run agentic verifier with tools

**Best Practices**:
- Validate inputs strictly in bash hooks
- Always quote bash variables (e.g., `"$CLAUDE_PROJECT_DIR"`)
- Return valid JSON for decisions (`allow`/`deny`) and messages
- Exit codes: 0 (success), 1 (non-blocking), 2 (blocking error)

See `./references/components/hooks.md` for complete hook patterns and templates.

## Agent Teams vs Subagents

### Subagents

Plugin-defined autonomous subprocesses with isolated context and restricted tools.

**When to Use**:
- Isolated, specialized decision-making with dedicated system prompt
- Sequential or single-direction workflow
- Focused tasks where only the result matters
- Lower token cost preferred

**Characteristics**:
- Defined as `.md` files in `agents/` directory
- Isolated context, restricted tool allowlists
- 2-4 `<example>` blocks for router-friendliness
- Results summarized back to main context

**Usage**:
```markdown
Launch `plugin-name:agent-name` agent to handle this task.
```

### Agent Teams (Experimental)

Multiple Claude Code sessions with shared task list and direct inter-agent communication. Can spawn plugin subagents or built-in agent types as teammates.

**When to Use**:
- **Research and review**: Parallel investigation with shared findings and challenges
- **New modules/features**: Each teammate owns separate piece
- **Debugging**: Competing hypotheses tested in parallel
- **Cross-layer coordination**: Frontend, backend, tests split across teammates

**When NOT to Use**:
- Sequential tasks, same-file edits, high-dependency work
- Coordination overhead exceeds benefit
- Routine tasks (single session more cost-effective)

**Comparison**:

| | Subagents | Agent Teams |
|---|---|---|
| Context | Returns to caller | Fully independent |
| Communication | To main agent only | Direct peer-to-peer |
| Coordination | Managed by main agent | Shared task list |
| Token cost | Lower (summarized) | Higher (full instances) |

**Usage**:

**Plugin subagents as teammates**:
```markdown
Create an agent team with plugin-defined agents:
- plugin-name:specialist-a for aspect A
- plugin-name:specialist-b for aspect B
```

**Built-in agent types**:
```markdown
Create an agent team with specialized reviewers:
- Explore agent focused on dimension 1
- Explore agent focused on dimension 2
- general-purpose agent for synthesis
```

**Enable**:
```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

**Best Practices**:
- Give teammates specific context and avoid file conflicts
- Size tasks appropriately (self-contained units with clear deliverables)
- Tell lead to "Wait for teammates to finish" if coordination needed
- Start with research/review tasks before parallel implementation

**Limitations**: No resumption, one team per session, no nesting, fixed lead, slow shutdown.

See `./references/agent-teams.md` for complete guide and `./references/component-model.md` for agent usage patterns.

## Parallel Agent Execution

**When to Use**:
- Tasks are independent and results can be merged afterward
- Multiple analyses can run simultaneously

**Request Patterns**:
- Explicit: "Launch all agents simultaneously: X agent, Y agent, Z agent"
- Phrasing: "Launch 3 parallel agents to process different aspects independently"

**Best Practices**:
- "parallel" or "simultaneously" appears explicitly in the request
- Descriptive style names the agent and intent
- Consolidation merges findings and resolves conflicts

**Common Pattern**:
1. Sequential setup (if needed)
2. Launch specialized analyses in parallel
3. Consolidate results and present unified output

See `./references/parallel-execution.md` for parallel coordination patterns.

## Reference Directory

### Validation & Quality
- `./references/validation-checklist.md` - Complete quality checklist
- `./references/rfc-2119.md` - Requirement levels (MUST/SHOULD/MAY)

### Component Implementation
- `./references/component-model.md` - Component types, selection criteria, token budgets
- `./references/components/skills.md` - Skill structure, frontmatter, progressive disclosure
- `./references/components/agents.md` - Agent design, CO-STAR framework, example blocks
- `./references/components/commands.md` - Command frontmatter, dynamic context
- `./references/components/hooks.md` - Hook events, types, bash templates
- `./references/components/mcp-servers.md` - MCP configuration, stdio/http/sse
- `./references/components/lsp-servers.md` - LSP setup, binary requirements

### Configuration & Integration
- `./references/directory-structure.md` - Plugin layout, naming conventions
- `./references/manifest-schema.md` - plugin.json schema, required fields
- `./references/mcp-patterns.md` - MCP transport types, security best practices

### Development Patterns
- `./references/tool-invocations.md` - Tool usage patterns and anti-patterns
- `./references/task-management.md` - TaskCreate patterns, dual-form naming
- `./references/cli-commands.md` - CLI commands for plugin management

### Advanced Topics
- `./references/agent-teams.md` - Parallelizable tasks, multi-perspective analysis
- `./references/parallel-execution.md` - Parallel agent coordination patterns
- `./references/debugging.md` - Common issues, error messages, troubleshooting