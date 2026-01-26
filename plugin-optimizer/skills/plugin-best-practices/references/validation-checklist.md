# Validation Checklist

Complete checklist for plugin quality assurance.

## Structure & Organization

- Skills SKILL.md target ~500 tokens (recommended, not enforced - warnings issued if exceeded)
- Progressive disclosure: core instructions in SKILL.md, detailed content in `references/` subdirectory
- Skill descriptions are concise trigger phrases (~50 tokens for metadata tier)
- Component names use kebab-case
- Components live at plugin root, not inside `.claude-plugin/`
- Component paths are relative and start with `./`

**Token Budget Guidelines**:
- **~50 tokens** (Tier 1 - Metadata): Description in frontmatter, loaded during discovery
- **~500 tokens** (Tier 2 - SKILL.md): Core instructions, loaded when invoked (target, not limit)
- **2000+ tokens** (Tier 3 - References): Detailed docs in `references/`, loaded on demand

**Note**: Token targets are recommendations for optimal context usage. Exceeding 500 tokens in SKILL.md triggers warnings but does not prevent validation from passing. Include critical information even if it causes slight overages.

## Agent Requirements

- Agents include clear delegation descriptions and a single responsibility
- Agent descriptions include 2–4 `<example>` blocks

## Scripts

- Scripts are executable with shebangs
- Scripts use `${CLAUDE_PLUGIN_ROOT}` paths

## Tool Invocations

- Tool invocations avoid explicit tool-call phrasing (see `./tool-invocations.md`)
- User interaction uses explicit format: "Use `AskUserQuestion` tool to [action]"
- Skill references use qualified names (`plugin-name:skill-name`)

## Configuration

- Skills and commands are declared in `plugin.json` (recommended)
- Skill type matches manifest and writing style:
  - Instruction-type uses imperative voice
  - Knowledge-type uses declarative voice

## Prompt Repetition Guidelines

- Critical rules and safety constraints MAY appear in multiple phases when execution depends on it
- Strategic repetition is allowed for: core rules, safety constraints, MUST/SHOULD requirements, templates, and examples
- Repetition favors concise restatement rather than verbatim duplication
