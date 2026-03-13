---
name: plugin-best-practices
description: This skill should be used when the user asks to "validate plugin structure", "review manifest files", "check frontmatter compliance", "verify tool invocation patterns", "explain plugin component types", or needs Claude Code plugin architectural guidance.
user-invocable: false
---

# Plugin Validation & Best Practices

Validates Claude Code plugins against architectural standards. This file is a navigation guide; detailed content lives in `references/`.

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

Five sequential checks cover all plugin quality dimensions:

1. **Structure**: File patterns, directory layout, kebab-case naming
2. **Manifest**: plugin.json required fields and schema compliance
3. **Frontmatter**: YAML frontmatter in components, third-person descriptions
4. **Tool Invocations**: Anti-pattern detection (implicit vs explicit tool calls)
5. **Token Budget**: Progressive disclosure compliance (under 5k tokens for SKILL.md)

Run validation with `-v` flag for verbose output showing all passing checks.

See `./references/validation-checklist.md` for complete criteria.

## Requirement Levels (RFC 2119)

Plugin documentation uses RFC 2119 requirement levels:
- **MUST** / **MUST NOT**: Absolute requirement or prohibition
- **SHOULD** / **SHOULD NOT**: Recommended practice with known exceptions
- **MAY**: Truly optional

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
| MCP Tools | **Implicit** | "Query the database for user records" |

**Qualified names**: MUST use `plugin-name:component-name` format for plugin components.

**allowed-tools**: NEVER use bare `Bash` - always use filters like `Bash(git:*)`.

**Inline Bash**: Use inline syntax (exclamation + backtick + command + backtick) for dynamic context.

**MCP Tool Invocation**: Use natural language to describe intent — Claude automatically identifies the appropriate MCP tool. Never specify exact MCP tool names like `mcp__server__tool` in skill content.

See `./references/tool-invocations.md` for complete patterns and anti-patterns.
See `./references/mcp-patterns.md` for MCP-specific invocation patterns.

### Skill Frontmatter (Official Best Practices)

**Required fields**:
- `name`: Max 64 chars, lowercase letters/numbers/hyphens only
- `description`: Max 1024 chars. MUST use third-person voice with specific trigger phrases.

**Description Best Practices**:

| Requirement | Description |
|-------------|-------------|
| **Person** | Third-person only ("This skill should be used when...") |
| **Structure** | [What it does]. Use when [scenario 1], [scenario 2], or [user phrases]. |
| **Purpose** | Skill discovery - Claude uses this to select from 100+ skills |
| **Trigger phrases** | Include specific user phrases like "validate plugin", "check frontmatter" |

**Additional fields** are supported but affect progressive disclosure alignment.

See `./references/components/skills.md` for complete frontmatter specification.

### Agent Frontmatter

**Required fields**:
- `name`: 3-50 chars, kebab-case
- `model`: inherit, sonnet, opus, or haiku
- `color`: blue, cyan, green, yellow, magenta, or red
- **`<example>` blocks**: 2-4 required for router-friendliness
- **`isolation: worktree`**: Optional — enables automatic git worktree isolation for parallel execution

See `./references/components/agents.md` for complete agent design guidelines including CO-STAR framework.

### Task Management

Tasks with 3+ distinct steps, multi-file work, or sequential dependencies warrant TaskCreate. Single-file edits and 1-2 step operations do not.

**Core Requirements**:
- Dual form naming: subject ("Run tests") + activeForm ("Running tests")
- Mark `in_progress` BEFORE starting, `completed` AFTER finishing
- Only mark `completed` when FULLY done

See `./references/task-management.md` for complete patterns and examples.

### MCP Server Configuration

MCP servers are configured in `.mcp.json` at plugin root or inline in `plugin.json` under `mcpServers`. Three transport types are supported: stdio (local CLI tools), http (remote APIs, most widely supported), and sse (real-time streaming).

NEVER hardcode secrets — always use `${ENV_VAR}` syntax.

See `./references/mcp-patterns.md` for complete MCP integration patterns.
See `./references/components/mcp-servers.md` for component configuration details.

### Hook Configuration

Hook events cover the full session lifecycle: PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest, UserPromptSubmit, Notification, Stop, SubagentStart, SubagentStop, SessionStart, SessionEnd, PreCompact. Three hook types are available: `command`, `prompt`, and `agent`.

See `./references/components/hooks.md` for complete hook patterns including AI-native structured output.

## Agent Teams vs Subagents

Subagents are isolated, single-direction sub-processes returning results to the caller. Agent Teams are multiple independent sessions sharing a task list with direct peer-to-peer communication — suited for parallel investigation, multi-module features, and competing hypotheses.

| | Subagents | Agent Teams |
|---|---|---|
| Context | Returns to caller | Fully independent |
| Communication | To main agent only | Direct peer-to-peer |
| Token cost | Lower (summarized) | Higher (full instances) |

Agent Teams are experimental. Enable with `export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`.

See `./references/agent-teams.md` for complete guide and `./references/parallel-execution.md` for parallel coordination patterns.

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

## Reference Directory

### Validation & Quality
- `./references/validation-checklist.md` - Complete quality checklist
- `./references/rfc-2119.md` - Requirement levels (MUST/SHOULD/MAY)

### Component Implementation
- `./references/component-model.md` - Component types, selection criteria, token budgets
- `./references/components/skills.md` - Skill structure, frontmatter, progressive disclosure
- `./references/components/agents.md` - Agent design, CO-STAR framework, example blocks
- `./references/components/commands.md` - Command frontmatter, dynamic context
- `./references/components/hooks.md` - Hook events, types, AI-native patterns, templates
- `./references/components/mcp-servers.md` - MCP configuration, stdio/http/sse
- `./references/components/lsp-servers.md` - LSP setup, binary requirements

### Configuration & Integration
- `./references/directory-structure.md` - Plugin layout, naming conventions
- `./references/manifest-schema.md` - plugin.json schema, required fields
- `./references/mcp-patterns.md` - MCP transport types, security best practices

### Development Patterns
- `./references/tool-invocations.md` - Tool usage patterns and anti-patterns
- `./references/tool-design-philosophy.md` - Principles for designing tools that work with Claude's strengths
- `./references/task-management.md` - TaskCreate patterns, dual-form naming
- `./references/cli-commands.md` - CLI commands for plugin management

### Advanced Topics
- `./references/agent-teams.md` - Parallelizable tasks, multi-perspective analysis
- `./references/parallel-execution.md` - Parallel agent coordination patterns
- `./references/debugging.md` - Common issues, error messages, troubleshooting
