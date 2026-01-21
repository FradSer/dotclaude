---
name: plugin-best-practices
description: This skill should be used when the user asks to "validate a plugin", "optimize plugin", "check plugin quality", "review plugin structure", "find plugin issues", "check best practices", "analyze plugin", or mentions plugin validation, optimization, or quality assurance.
version: 0.1.0
---

# Plugin Best Practices Validation

Comprehensive knowledge base for validating and optimizing Claude Code plugins against official standards.

## Purpose

This skill provides structured validation knowledge for analyzing Claude Code plugins. Use it when checking plugin quality, identifying issues, or generating optimization recommendations.

## Official Documentation

For the latest official Claude Code documentation, use the `claude-code-guide` agent to search and retrieve information about:
- Plugin development guidelines
- Component specifications (agents, commands, skills, hooks)
- API references and tool usage
- Best practices and examples

## Core Philosophy

**Minimal Configuration**: Rely on auto-discovery. Do not manually list commands, agents, or skills in plugin.json unless absolutely necessary.

**Standard Directory Structure**: Place components in root directories (commands/, agents/, skills/, hooks/) for automatic discovery.

**Tool Usage Rules**:
- Core file tools (Read, Write, Glob, Grep, Edit): Describe actions implicitly ("Find files matching...", "Read the configuration...")
- Skill tool: Always explicit ("Load the X skill using the Skill tool")
- Bash: Describe commands ("Run `git status`") rather than tool invocation

**Portable Paths**: Always use `${CLAUDE_PLUGIN_ROOT}` for file references. Never hardcode absolute paths.

**Naming Convention**: Use kebab-case for all files and directories (code-review.md, api-testing/).

**Component Decoupling**: Components (skills/agents/commands) must be independent and self-contained. See `references/directory-structure.md` and component-specific references for implementation details.

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
- Components (skills/agents/commands) are decoupled and do not directly reference each other

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

## Reference Resources & Scenario Guide

Use this guide to select the correct reference file based on the specific validation task or scenario encountered.

### 1. Structure & Manifest Validation
**Scenario**: Users report "plugin not found" or "invalid configuration".
- **Directory Layout**: usage of `references/directory-structure.md` - Validates file hierarchy, naming conventions (kebab-case), and component placement.
- **Manifest Configuration**: usage of `references/manifest-schema.md` - checks `plugin.json` fields, `marketplace.json` requirements, and metadata standards.

### 2. Component Implementation
**Scenario**: "How do I create an X?" or "Validation failed for component Y".
- **Commands**: `references/components/commands.md` - For `options`, `arguments`, and inline execution syntax.
- **Agents**: `references/components/agents.md` - For system prompts, persona definition, and triggering example blocks.
- **Skills**: `references/components/skills.md` - For `SKILL.md` structure, progressive disclosure patterns, and instruction formats.
- **Hooks**: `references/components/hooks.md` - For `PreStep`/`PostStep` triggers, `hooks.json` config, and exit code handling.
- **Common Patterns**: `references/component-patterns.md` - Shared best practices applicable across all components (VSCode compatibility, error handling).

### 3. Advanced Integrations & External Tools
**Scenario**: Integrating external servers/tools or fixing tool call errors.
- **MCP Servers**: `references/components/mcp-servers.md` & `references/mcp-patterns.md` - For defining and configuring Model Context Protocol servers.
- **LSP Servers**: `references/components/lsp-servers.md` - For Language Server Protocol integration details.
- **Tool Invocations**: `references/tool-invocations.md` - **CRITICAL**: Distinguishing between correct tool descriptions and forbidden explicit tool calls.

### 4. Workflow, Debugging & Documentation
**Scenario**: "Why isn't it working?" or "How do I test this?".
- **Debugging**: `references/debugging.md` - Strategies for diagnosing agent loops, tool failures, and state issues.
- **CLI Operations**: `references/cli-commands.md` - Reference for `claude` CLI commands used in testing and maintenance.
- **Documentation Standards**: `references/todowrite-usage.md` - Guidelines for using TodoWrite to maintain plugin context and documentation.

Load specific reference files as needed to provide detailed validation logic without overwhelming the context.
