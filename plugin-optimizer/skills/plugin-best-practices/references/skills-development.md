# Skill Implementation Patterns

Complete guide to creating effective skills for Claude Code plugins.

## 4. Skill Implementation

**Must Do**

- **Use Imperative Style:** Write SKILL.md bodies using verb-first instructions ("Parse the file...", "Validate the input...") rather than second person ("You should...").
- **Third-Person Descriptions:** Write frontmatter descriptions in the third person with specific trigger phrases ("This skill should be used when the user asks to...").
- **Structure Correctly:** Place the `SKILL.md` file inside a subdirectory (e.g., `skills/my-skill/SKILL.md`).

**Should Do**

- **Manage Visibility:** Use `user-invocable: false` for utility skills that should only be called by agents, not directly by users via slash commands.
- **Isolate Context:** Use `context: fork` in frontmatter for skills that perform complex analysis or side tasks, preserving the main conversation context.
- **Progressive Disclosure:** Keep `SKILL.md` lean (1,500-2,000 words). Move detailed documentation to `references/` and code to `examples/` or `scripts/`.
- **Bundle Resources:** Include static assets (templates, schemas) in `assets/` and executable utilities in `scripts/`.
- **Reference Resources:** Explicitly mention the existence of your reference files and scripts in the main `SKILL.md` so Claude knows they exist.

**Avoid**

- **Monolithic Files:** Don't dump 5,000+ words into `SKILL.md`. It bloats the context window.
- **Duplication:** Do not repeat information between `SKILL.md` and `references/` files.

## Skill Directory Structure

```
skills/
└── skill-name/
    ├── SKILL.md              # Required: Main skill file
    ├── references/           # Optional: Detailed documentation
    │   ├── patterns.md
    │   └── advanced.md
    ├── examples/             # Optional: Working code examples
    │   └── example.sh
    ├── scripts/              # Optional: Utility scripts
    │   └── validate.sh
    └── assets/               # Optional: Templates, static files
        └── template.json
```

## SKILL.md Frontmatter

**Required fields:**

```yaml
---
name: skill-name
description: This skill should be used when the user asks to "specific phrase 1", "specific phrase 2", or mentions "keyword". Include exact trigger phrases.
---
```

**Optional fields:**

```yaml
---
name: skill-name
description: This skill should be used when...
version: 1.0.0
license: MIT
user-invocable: false
context: fork
---
```

## Description Best Practices

**Good descriptions:**

```yaml
# Specific trigger phrases
description: This skill should be used when the user asks to "create a hook", "add a PreToolUse hook", "validate tool use", or mentions hook events (PreToolUse, PostToolUse, Stop).

# Multiple trigger patterns
description: This skill should be used when the user asks to "configure MCP server", "add MCP integration", "set up Model Context Protocol", or mentions MCP server types (SSE, stdio, HTTP).

# Domain-specific keywords
description: This skill should be used when the user asks to "optimize plugin", "check best practices", "validate plugin structure", or mentions plugin validation or quality assurance.
```

**Bad descriptions:**

```yaml
# Too vague
description: Provides guidance for working with plugins.

# Not third person
description: Use this skill when you need to create hooks.

# No trigger phrases
description: Hook development skill.
```

## SKILL.md Body Writing Style

**Use imperative/infinitive form:**

```markdown
# Correct - Imperative form
Parse the configuration file to extract settings.
Validate the input before processing.
Generate the output file in the specified format.

# Incorrect - Second person
You should parse the configuration file.
You need to validate the input.
You can generate the output file.
```

**Structure the content:**

```markdown
# Skill Name

[Purpose and overview - 1-2 paragraphs]

## Core Concepts

[Key concepts and definitions]

## Workflow

1. [Step 1]
2. [Step 2]
3. [Step 3]

## Best Practices

- [Practice 1]
- [Practice 2]

## Additional Resources

### Reference Files

- **`references/patterns.md`** - Detailed patterns
- **`references/advanced.md`** - Advanced techniques

### Scripts

- **`scripts/validate.sh`** - Validation utility
```

## Progressive Disclosure Strategy

**SKILL.md (1,500-2,000 words):**
- Core concepts and overview
- Essential procedures
- Quick reference
- Pointers to references/examples/scripts
- Most common use cases

**references/ (detailed content):**
- Detailed patterns and techniques
- Comprehensive documentation
- Migration guides
- Edge cases and troubleshooting
- Each file can be 2,000-5,000+ words

**examples/ (working code):**
- Complete, runnable examples
- Configuration files
- Template files
- Real-world usage

**scripts/ (utilities):**
- Validation tools
- Testing helpers
- Parsing utilities
- Automation scripts

## Resource Referencing

**Explicitly mention resources in SKILL.md:**

```markdown
## Validation Scripts

The skill includes utilities in `scripts/`:

**validate-config.sh**:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/skill-name/scripts/validate-config.sh
```
Validates configuration syntax and required fields.

**run-tests.sh**:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/skill-name/scripts/run-tests.sh
```
Runs test suite against examples.

## Reference Documentation

For detailed patterns, consult:

- **`references/patterns.md`** - Common implementation patterns
- **`references/api-reference.md`** - Complete API documentation
- **`references/migration.md`** - Migration guide from older versions

## Examples

Working examples in `examples/`:

- **`examples/basic-usage.sh`** - Basic usage example
- **`examples/advanced-config.json`** - Advanced configuration
```

## Skill Frontmatter Fields Reference

| Field | Required | Values | Purpose |
|-------|----------|--------|---------|
| name | Yes | string | Skill identifier |
| description | Yes | string | When to trigger (with phrases) |
| version | No | semver | Version tracking |
| license | No | string | License identifier |
| user-invocable | No | boolean | Allow slash command usage |
| context | No | fork/inherit | Context isolation |

## Common Patterns

### Minimal Skill

```
skill-name/
└── SKILL.md
```

Use for simple knowledge with no complex resources.

### Standard Skill (Recommended)

```
skill-name/
├── SKILL.md
├── references/
│   └── detailed-guide.md
└── examples/
    └── working-example.sh
```

Use for most plugin skills with detailed documentation.

### Complete Skill

```
skill-name/
├── SKILL.md
├── references/
│   ├── patterns.md
│   └── advanced.md
├── examples/
│   ├── example1.sh
│   └── example2.json
└── scripts/
    └── validate.sh
```

Use for complex domains with validation utilities.

## Validation Checklist

Before finalizing a skill:

**Structure:**
- [ ] SKILL.md exists in subdirectory
- [ ] Frontmatter has name and description
- [ ] Referenced files actually exist

**Description Quality:**
- [ ] Uses third person
- [ ] Includes specific trigger phrases
- [ ] Lists concrete scenarios
- [ ] Not vague or generic

**Content Quality:**
- [ ] Body uses imperative form
- [ ] Body is lean (1,500-2,000 words ideal, <3,000 max for body alone)
- [ ] Detailed content in references/
- [ ] Examples are complete and working
- [ ] Scripts are executable

**Progressive Disclosure:**
- [ ] Core concepts in SKILL.md
- [ ] Detailed docs in references/
- [ ] Working code in examples/
- [ ] Utilities in scripts/
- [ ] SKILL.md references resources

## Common Mistakes

**Mistake 1: Weak Trigger Description**

```yaml
# Bad
description: Provides guidance for working with hooks.

# Good
description: This skill should be used when the user asks to "create a hook", "add a PreToolUse hook", "validate tool use", or mentions hook events.
```

**Mistake 2: Too Much in SKILL.md**

```
# Bad
skill-name/
└── SKILL.md  (8,000 words - everything in one file)

# Good
skill-name/
├── SKILL.md  (1,800 words - core essentials)
└── references/
    ├── patterns.md (2,500 words)
    └── advanced.md (3,700 words)
```

**Mistake 3: Second Person Writing**

```markdown
# Bad
You should start by reading the configuration file.
You need to validate the input.

# Good
Start by reading the configuration file.
Validate the input before processing.
```

**Mistake 4: Missing Resource References**

```markdown
# Bad - SKILL.md with no mention of references/

# Good
## Additional Resources

### Reference Files
- **`references/patterns.md`** - Detailed patterns

### Examples
- **`examples/script.sh`** - Working example
```

## Example: Well-Structured Skill

**skills/plugin-validation/SKILL.md:**

```yaml
---
name: plugin-validation
description: This skill should be used when the user asks to "validate a plugin", "check plugin quality", "review plugin structure", or mentions plugin optimization or best practices compliance.
version: 1.0.0
---
```

```markdown
# Plugin Validation

Comprehensive knowledge for validating Claude Code plugins against official standards.

## Purpose

Validate plugin structure, components, and patterns. Check for common issues like missing metadata, explicit tool invocations, and format violations.

## Core Validation Categories

1. Structure & Organization
2. Command Development
3. Agent Design
4. Skill Implementation
5. Tool Invocation Patterns

## Validation Workflow

1. Load this skill
2. Scan plugin structure
3. Validate each component type
4. Check tool invocations
5. Generate categorized report

## Severity Levels

- **Critical**: Must fix (missing required fields, broken references)
- **Warning**: Should fix (anti-patterns, weak descriptions)
- **Info**: Nice to have (missing optional metadata)

## Validation Scripts

Use utilities in `scripts/`:

**validate-plugin-json.sh**:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/plugin-validation/scripts/validate-plugin-json.sh /path/to/plugin
```

## Additional Resources

### Reference Files

- **`references/structure.md`** - Structure patterns
- **`references/commands.md`** - Command patterns
- **`references/agents.md`** - Agent patterns
- **`references/tool-patterns.md`** - Tool invocation patterns

### Examples

- **`examples/good-plugin/`** - Well-structured example
- **`examples/common-issues/`** - Common mistakes
```

This example demonstrates:
- Third-person description with trigger phrases
- Imperative form in body
- Lean SKILL.md (under 2,000 words)
- Clear resource references
- Progressive disclosure strategy
