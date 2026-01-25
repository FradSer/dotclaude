# Knowledge-Type Skill Template

**Purpose**: Provide background knowledge for agents.

**Frontmatter Requirements**:
```yaml
---
name: domain-standards
description: Provides validation rules and best practices for domain
user-invocable: false
---
```

**Writing Style Requirements**:
- Use declarative voice: "Skills are...", "Components provide...", "Use when..."
- Never use imperative commands: avoid "Load", "Create", "Execute"

**Structure Requirements**:
- Topic-based sections: "## Core Concepts", "## Best Practices", "## Patterns"
- Use reference tables, definitions, rule lists
- Include examples illustrating concepts (not action steps)
- Keep under 200 lines; use `references/` for detailed content

**Complete Template**:
```markdown
---
name: domain-standards
description: Provides validation rules and best practices for domain
user-invocable: false
---

# Domain Standards

Standards and validation rules for domain components.

## Core Concepts

Components are modular units that extend functionality.

**Component Types**:
- Type A — Purpose and characteristics
- Type B — Purpose and characteristics

## Validation Rules

Components MUST follow these requirements:
- Rule 1: Specific requirement with rationale
- Rule 2: Specific requirement with rationale

Components SHOULD apply these best practices:
- Practice 1: Recommendation with benefit
- Practice 2: Recommendation with benefit

## Usage Patterns

Use Type A components when:
- Scenario 1 with example
- Scenario 2 with example
```

## Validation Checklist for Skills

- [ ] Frontmatter `user-invocable` matches content style (imperative vs declarative)
- [ ] plugin.json declaration matches type (commands vs skills array)
- [ ] Content follows appropriate template structure (phases vs topics)
- [ ] Writing style consistent throughout (imperative vs declarative)
- [ ] All paths use correct format (relative `./` or `${CLAUDE_PLUGIN_ROOT}`)
- [ ] Bash tool restrictions present in allowed-tools (never bare `Bash`)
