# Component Model

Detailed overview of Claude Code plugin component types.

## Skills

Skills are markdown prompts that run in the main conversation context and extend knowledge or provide workflows.

Two skill types are supported:
- **Instruction-type** (`user-invocable: true` → `commands`): imperative voice, phase-based workflows (with optional "Initialization" and "Background Knowledge" pre-phase sections), user-invoked.
- **Knowledge-type** (`user-invocable: false` → `skills`): declarative voice, topic-based references, auto-loaded.

### Progressive Disclosure

Skills use a three-tier token budget structure:

| Tier | Location | Token Target | Loading | Purpose |
|------|----------|--------------|---------|---------|
| 1 | Frontmatter description | ~50 tokens | Discovery phase | Trigger phrases for routing |
| 2 | SKILL.md body | ~500 tokens | Skill invocation | Core instructions and workflow |
| 3 | references/ files | 2000+ tokens | On-demand | Detailed specs, examples, reference material |

**Important**: Token targets are recommendations, not hard limits. Validation scripts warn when SKILL.md exceeds ~500 tokens but do NOT fail validation. Include critical information in SKILL.md even if it causes moderate overages (600-700 tokens acceptable if necessary).

## Agents

Agents are autonomous subprocesses with isolated context and their own system prompts.

Key characteristics:
- Isolated context with a dedicated system prompt in the agent `.md` file
- Restricted tool allowlists for safety and focus
- Specialized expertise with judgment over execution details
- Router-friendly descriptions containing 2–4 `<example>` blocks

## Selection Guide

- **Instruction-type skills** apply when a user invokes a workflow via slash command and the process is linear
- **Knowledge-type skills** apply when providing reference knowledge for agents or the main session
- **Agents** apply when isolation, specialization, and autonomous decision-making are required

## plugin.json Declaration

| Config | User invocable | Claude invocable | Declare in |
|--------|----------------|------------------|------------|
| `user-invocable: false` | No | Yes | `skills` (knowledge-type) |
| (default) or `user-invocable: true` | Yes | Yes | `commands` (instruction-type) |
| `disable-model-invocation: true` | Yes | No | `commands` (instruction-type, no auto-invoke) |
