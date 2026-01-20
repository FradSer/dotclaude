---
name: plugin-best-practices
description: This skill should be used when the user asks to "validate a plugin", "optimize plugin", "check plugin quality", "review plugin structure", "find plugin issues", "check best practices", "analyze plugin", or mentions plugin validation, optimization, or quality assurance.
version: 0.1.0
---

# Plugin Best Practices Validation

Comprehensive knowledge base for validating and optimizing Claude Code plugins against official standards.

## Purpose

This skill provides structured validation knowledge for analyzing Claude Code plugins. Use it when checking plugin quality, identifying issues, or generating optimization recommendations.

## Core Philosophy

**Minimal Configuration**: Rely on auto-discovery. Do not manually list commands, agents, or skills in plugin.json unless absolutely necessary.

**Standard Directory Structure**: Place components in root directories (commands/, agents/, skills/, hooks/) for automatic discovery.

**Tool Usage Rules**:
- Core file tools (Read, Write, Glob, Grep, Edit): Describe actions implicitly ("Find files matching...", "Read the configuration...")
- Skill tool: Always explicit ("Load the X skill using the Skill tool")
- Bash: Describe commands ("Run `git status`") rather than tool invocation

**Portable Paths**: Always use `${CLAUDE_PLUGIN_ROOT}` for file references. Never hardcode absolute paths.

**Naming Convention**: Use kebab-case for all files and directories (code-review.md, api-testing/).

## Quick Reference

**Critical Component Requirements**:
- Agents: Must have 2-4 `<example>` blocks in description, second-person system prompts
- Skills: SKILL.md in subdirectory, third-person description, progressive disclosure pattern
- Commands: Frontmatter with description, instructions FOR Claude, tool restrictions via allowed-tools
- Hooks: Event-driven validation, exit codes (0=allow, 2=block)

**File Locations**:
- Manifest: `.claude-plugin/plugin.json`
- Components: `commands/*.md`, `agents/*.md`, `skills/*/SKILL.md`
- Configuration: `hooks/hooks.json`, `.mcp.json`

**Common Validation Checks**:
- Plugin.json has name, description, author.name
- All components use kebab-case naming
- No explicit tool invocations in component instructions
- Agents have triggering examples in descriptions
- Skills use imperative form, not second person

## Core Validation Categories

Plugin validation covers seven main categories. For detailed checks and patterns, consult the corresponding reference files:

1. **Plugin Structure & Organization** - Manifest location, component directories, naming conventions, portable paths
2. **Command Development** - Frontmatter, instructions style, tool restrictions, inline bash syntax
3. **Agent Design** - Frontmatter fields, example blocks, system prompts, output formats
4. **Skill Implementation** - File location, description style, progressive disclosure, body content
5. **Tool Invocation Patterns** - Correct vs anti-pattern tool references in component instructions
6. **File Format Patterns** - YAML frontmatter, markdown structure, naming conventions
7. **Manifest Quality** - Required/optional fields for plugin.json and marketplace.json

See "Progressive Disclosure Strategy" section below for reference file mappings.

## Validation Workflow

When validating a plugin:

1. **Load this skill** to access validation knowledge
2. **Scan structure**: Check directory layout, manifest, component locations
3. **Validate components**: For each component type (commands, agents, skills), check:
   - File format and frontmatter
   - Content patterns and anti-patterns
   - Naming conventions
4. **Check tool invocations**: Search for explicit tool call anti-patterns
5. **Review metadata**: Verify completeness of manifest and frontmatter fields
6. **Generate report**: Categorize issues by severity (critical/warning/info)
7. **Provide fixes**: Suggest exact Edit tool parameters for each issue

## Severity Levels

Categorize validation issues into three severity levels:

- **Critical** - Must fix before plugin works correctly
- **Warning** - Should fix for best practices compliance
- **Info** - Nice to have improvements for quality and discoverability

See reference files for specific examples of each severity level.

## Additional Resources

### Reference Files

For detailed validation patterns, consult these reference files:

- **`references/structure-organization.md`** - Plugin Structure & Organization (Section 1)
- **`references/commands.md`** - Command Development patterns (Section 2)
- **`references/agents.md`** - Agent Design standards (Section 3)
- **`references/skills-development.md`** - Skill Implementation guidelines (Section 4)
- **`references/tool-invocations.md`** - Tool Invocation Patterns (Section 5)
- **`references/file-patterns.md`** - Complete file format patterns (Section 6)
- **`references/manifests.md`** - Manifest patterns (Section 7)
- **`references/hooks.md`** - Hook Usage patterns
- **`references/mcp.md`** - MCP Integration patterns and configuration
- **`references/todowrite.md`** - TodoWrite Tool Usage Standards

### Example Files

Working examples in `examples/`:

- **`examples/good-plugin/`** - Well-structured plugin demonstrating best practices
- **`examples/common-issues/`** - Examples of common mistakes and how to fix them

## Best Practices for Using This Skill

**When analyzing a plugin:**

1. Start with structure validation (manifest, directories)
2. Validate each component type systematically
3. Consult specific reference files for detailed patterns
4. Categorize all issues by severity
5. Provide actionable fix suggestions with exact parameters

**When generating reports:**

1. Summary section with compliance checklist
2. Issues grouped by severity (critical/warning/info)
3. Each issue with file:line reference
4. Auto-fix suggestions with Edit tool parameters
5. Overall quality assessment

**When fixing issues:**

1. Address critical issues first
2. Use provided Edit tool parameters
3. Re-validate after fixes
4. Iterate until all critical issues resolved

## Progressive Disclosure Strategy

Load reference files based on validation focus:

- **Structure issues** → `references/structure-organization.md`
- **Command issues** → `references/commands.md`
- **Agent issues** → `references/agents.md`
- **Skill issues** → `references/skills-development.md`
- **Tool pattern issues** → `references/tool-invocations.md`
- **Format issues** → `references/file-patterns.md`
- **Manifest issues** → `references/manifests.md`
- **Hook issues** → `references/hooks.md`
- **MCP integration issues** → `references/mcp.md`

Reference files contain complete, detailed patterns and examples from the official best practices documentation. Load them as needed rather than keeping all context loaded.
