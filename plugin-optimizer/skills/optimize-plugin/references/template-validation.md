# Component Template Validation Rules

Detailed validation rules for plugin components against templates in `${CLAUDE_PLUGIN_ROOT}/examples/`.

## Agent Template Validation

For each file in `./agents/*.md`, verify:

### Frontmatter Requirements
- `name`: Present and matches filename
- `description`: Present (MAY include 2-4 `<example>` blocks for routing - optional)
- `color`: Present (valid values: blue, cyan, green, yellow, magenta, red)
- `allowed-tools`: Present (array of tool names)

### System Prompt Requirements
- Uses second person: "You are...", "You analyze...", "You perform..."
- Descriptive voice focusing on capabilities (NOT directive: avoid "Load...", "Execute...")

### Structure Requirements
- **Knowledge Base** section: Documents loaded skills and resources
- **Core Responsibilities** section: Numbered list of agent duties
- **Approach** section: Working principles and methodology

### Template Violations (flag as CRITICAL)
```text
agents/[agent-name].md uses imperative "Execute..." instead of descriptive "You execute..."
agents/[agent-name].md missing "## Core Responsibilities" section
```

## Instruction-Type Skill Validation

For each skill with `user-invocable: true` in frontmatter:

### Frontmatter Requirements
- `name`: Present
- `description`: Present (when to invoke skill)
- `user-invocable: true`: Must be explicitly set
- `allowed-tools`: Present (array of tool names)

### Writing Style Requirements
- Imperative voice: "Load...", "Create...", "Execute...", "Analyze..."
- NO declarative descriptions: avoid "is", "are", "provides"

### Structure Requirements (CRITICAL)

**MANDATORY Phase Format:**
- MUST use exact format: `## Phase N: [Phase Name]` where N is a number (1, 2, 3, ...)
- All execution sections MUST follow this pattern (any deviation is CRITICAL violation)
- Each phase MUST have both subsections:
  - `**Goal**:` - What this phase accomplishes (single sentence)
  - `**Actions**:` - Numbered list of steps (1., 2., 3., ...)
- Linear process flow from start to completion

**Validation Checklist:**
1. At least one `## Phase 1:` section exists
2. All execution sections use `## Phase N:` format (where N = 1, 2, 3...)
3. Each Phase section has `**Goal**:` subsection
4. Each Phase section has `**Actions**:` subsection
5. Actions use numbered lists (1., 2., 3., ...)
6. No execution section deviates from `## Phase N:` format pattern

**Optional Pre-Phase Sections:**
- `## Background Knowledge` - Domain knowledge, format specs, rules
- `## Initialization` - Setup steps before main workflow
- `## Context` - Environmental information

### Template Violations (flag as CRITICAL)
```text
skills/[skill-name]/SKILL.md has user-invocable:true but uses declarative voice
skills/[skill-name]/SKILL.md execution sections do not match "## Phase N:" format
skills/[skill-name]/SKILL.md has Phase sections but missing **Goal** and **Actions** subsections
```

## Knowledge-Type Skill Validation

For each skill with `user-invocable: false` or missing field:

### Frontmatter Requirements
- `name`: Present
- `description`: Present (domain/topic covered)
- `user-invocable: false`: Should be explicitly set or omitted

### Writing Style Requirements
- Declarative voice: "is", "are", "provides", "defines", "describes"
- NO imperative instructions: avoid "Load...", "Execute...", "Analyze..."

### Structure Requirements
- Topic-based sections: "## Core Concepts", "## Best Practices", "## Patterns"
- Reference content: definitions, tables, examples (NOT execution sequences)
- Teaching tone: "Skills are...", "Use when...", "Components MUST..."

### Template Violations (flag as CRITICAL)
```text
skills/[skill-name]/SKILL.md uses imperative "Execute..." instead of declarative style
skills/[skill-name]/SKILL.md has Phase structure (should use topic-based sections)
```

## Type Classification Quick Reference

| Component Type | user-invocable | Voice | Structure | Declared in |
|----------------|----------------|-------|-----------|-------------|
| Agent | N/A | Descriptive (You are...) | Knowledge Base + Core Responsibilities + Approach | `agents` |
| Instruction Skill | `true` | Imperative (Load...) | Phase-based (Goal + Actions) | `commands` |
| Knowledge Skill | `false` | Declarative (is/are...) | Topic-based (concepts/patterns) | `skills` |

## Manifest Cross-Validation

After classifying each skill:
1. Instruction-type MUST be in `plugin.json` `commands` array
2. Knowledge-type MUST be in `plugin.json` `skills` array
3. Flag mismatches as CRITICAL violations
