# Designing Agents

Agents are autonomous subprocesses with isolated context. Combine a **Persona** (System Prompt) with **Capabilities** (Tools/Skills) to solve problems.

## Frontmatter Structure

Agent frontmatter MUST follow this exact field order within the YAML block:

```yaml
---
name: agent-name
description: Use this agent when... <example>blocks required</example>
model: sonnet
color: cyan
effort: medium
maxTurns: 20
tools: ["Read", "Grep", "Glob"]
disallowedTools: ["Write", "Edit"]
skills:
  - plugin-name:skill-name
memory: persistent
background: false
isolation: worktree  # optional
---
```

**Field ordering rules**:
- `name` and `description` MUST come first
- All other YAML fields MUST appear immediately after `description`, before any `<example>` blocks
- `<example>` blocks MUST appear after all YAML fields and before the closing `---`

**Anti-pattern** — fields after `<example>` blocks are parsed as body text, not YAML:

```yaml
---
name: agent-name
description: ...

<example>...</example>

model: sonnet   # WRONG: not parsed as YAML frontmatter
tools: [...]    # WRONG: not parsed as YAML frontmatter
---
```

## Supported Frontmatter Fields

Per the upstream plugins-reference#agents:

| Field             | Required | Description                                                                                          |
| :---------------- | :------- | :--------------------------------------------------------------------------------------------------- |
| `name`            | Yes      | Kebab-case identifier, 3-50 chars                                                                    |
| `description`     | Yes      | What the agent specializes in and when Claude should invoke it. Include 2-4 `<example>` blocks.       |
| `model`           | No       | `inherit` (default), `sonnet`, `opus`, or `haiku`                                                    |
| `color`           | No       | UI accent: `blue`, `cyan`, `green`, `yellow`, `magenta`, or `red`                                    |
| `effort`          | No       | Reasoning budget hint                                                                                |
| `maxTurns`        | No       | Hard cap on agent loop iterations                                                                    |
| `tools`           | No       | Allowlist of tools the agent can call                                                                |
| `disallowedTools` | No       | Blocklist of tools (use this OR `tools`, not both)                                                   |
| `skills`          | No       | Skills available to the agent (`plugin-name:skill-name` form)                                        |
| `memory`          | No       | Memory configuration                                                                                  |
| `background`      | No       | Whether the agent runs in the background by default                                                  |
| `isolation`       | No       | Only valid value is `"worktree"` — creates a fresh git worktree per invocation                       |

## Forbidden Frontmatter Fields

Three fields are explicitly **not supported** for plugin-shipped agents (security restriction per upstream):

| Field            | Reason                                                                                  |
| :--------------- | :-------------------------------------------------------------------------------------- |
| `hooks`          | Plugin agents cannot register session hooks                                             |
| `mcpServers`     | Plugin agents cannot bring their own MCP server fleet                                   |
| `permissionMode` | Plugin agents cannot widen the user's tool-permission posture                           |

The plugin-optimizer validator emits a MUST violation if any of these appear in plugin agent frontmatter.

## Anatomy of a Robust Agent

### Persona (System Prompt)
Engineer the system prompt for reliability.

*   **Role Definition**: State "You are a [Role]. Your goal is [Goal]."
*   **Tone & Style**: Specify "Be concise." "Show your work." "Ask for confirmation before destructive actions."
*   **Constraints**: Define "Never edit files outside `/src`." "Always run tests after changes."

**CO-STAR Framework**:
*   **C**ontext: Background info.
*   **O**bjective: What to achieve.
*   **S**tyle: Tone/Format.
*   **T**one: Attitude.
*   **A**udience: Who is this for?
*   **R**esponse: Format of output.

### Tool Selection (Capabilities)
Adhere to the **Principle of Least Privilege**.
*   Give an agent *only* the tools it needs.
*   **Rationale**:
    *   **Safety**: A "Reader" agent shouldn't have `rm`.
    *   **Focus**: Fewer tools = less confusion.
    *   **Performance**: Smaller system prompt.

### Cognitive Load Management
*   **Scratchpads**: Encourage the agent to "think out loud" inside `<thinking>` blocks.
*   **Checklists**: Give the agent a checklist in its prompt to track progress.

## Agent Types in Plugins

| Type | Purpose | Tools | Example |
|------|---------|-------|---------|
| **Router** | Triage and redirect | None (or Task) | "Help Desk" |
| **Executor** | Do the work | Edit, Bash, Write | "Code Refactorer" |
| **Researcher** | Find info | Read, Search, Glob | "Log Analyzer" |
| **Verifier** | Quality Assurance | Bash (test), Read | "PR Reviewer" |

## Best Practices

1.  **Examples are Key**: Include 2-4 `<example>` blocks in the agent description. This is "Few-Shot Prompting" for the router. It teaches Claude *exactly* when to pick this agent.
2.  **Fail Fast**: Instruct agents to stop and report if prerequisites aren't met.
3.  **Hooks for Safety**: Use `PreToolUse` hooks to validate commands (e.g., preventing `git push --force` in a junior-dev agent). See `./references/components/hooks.md` for configuration.

## Worktree Isolation

Agents can run in isolated git worktrees to prevent file conflicts during parallel execution.

### Session-Level Worktree

Request worktree isolation during a session:

```markdown
"work in a worktree"
"start a worktree for this bug fix"
```

### Agent-Level Isolation (Strongest Mode)

Add `isolation: worktree` to agent frontmatter for automatic worktree creation:

```yaml
---
name: feature-implementer
description: Implements features in isolated worktrees
isolation: worktree
tools: Read, Write, Edit, Bash
---
```

**Behavior**:
- Each agent invocation creates a fresh worktree with its own branch
- Agent has complete filesystem isolation
- Worktree auto-cleans if no changes are made
- Ideal for parallel agents editing overlapping files

**When to Use**:
- Multiple agents working on same codebase simultaneously
- Parallel feature development with potential file conflicts
- Competitive implementation (N solutions, pick best)