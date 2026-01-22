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

**Script Executability**: Scripts (`.sh`, `.py`, `.js`, etc.) must be executable (`chmod +x`), have a correct shebang, use `${CLAUDE_PLUGIN_ROOT}` in paths, and run without extra setup.

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
- Scripts are executable with shebang and use `${CLAUDE_PLUGIN_ROOT}` in paths

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

Use this guide to select the correct reference file based on the specific validation task or scenario encountered. Each scenario maps to specific reference files with detailed validation patterns and best practices.

### Quick Lookup Index

| Issue/Question | Reference File | Key Section |
|----------------|----------------|-------------|
| Script not executing? | `references/debugging.md` | Hook script troubleshooting (lines 47-50) |
| Directory structure wrong? | `references/directory-structure.md` | Standard plugin layout |
| Tool invocation errors? | `references/tool-invocations.md` | Tool invocation rules |
| Component validation failed? | `references/components/[type].md` | Component-specific reference |
| Hook not triggering? | `references/debugging.md` | Hook troubleshooting (lines 45-57) |
| MCP server issues? | `references/debugging.md` | MCP server troubleshooting (lines 58-71) |
| Plugin.json errors? | `references/manifest-schema.md` | Manifest schema reference |
| Script missing shebang? | `references/components/hooks.md` | Bash hook template (line 70) |
| Script path errors? | `references/manifest-schema.md` | ${CLAUDE_PLUGIN_ROOT} usage (line 87) |

### 1. Structure & Manifest Validation

**When to use**: Validating plugin directory structure, file locations, naming conventions, or manifest configuration.

**Scenarios**:
- **Directory structure, file locations, naming**: Reference `references/directory-structure.md`
- **Manifest errors**: Reference `references/manifest-schema.md`
- **Script structure and executability**: Reference `references/directory-structure.md` + `references/debugging.md` (lines 47-50)

### 2. Component Implementation Validation

**When to use**: Validating or creating specific plugin components (commands, agents, skills, hooks, MCP servers, LSP servers).

**Scenarios**:
- **Commands**: Reference `references/components/commands.md`
- **Agents**: Reference `references/components/agents.md` (requires 2-4 example blocks)
- **Skills**: Reference `references/components/skills.md`
- **Hooks**: Reference `references/components/hooks.md` (exit codes: 0=allow, 2=block)
- **MCP Servers**: Reference `references/components/mcp-servers.md` & `references/mcp-patterns.md`
- **LSP Servers**: Reference `references/components/lsp-servers.md`

### 3. Tool Invocation Pattern Validation

**When to use**: Checking for correct vs incorrect tool usage patterns in component instructions.

**Scenarios**:
- **Tool invocation patterns**: Reference `references/tool-invocations.md` - **CRITICAL** for correct vs incorrect tool usage

### 4. Script Validation

**When to use**: Validating script executability, shebang lines, and path configuration.

**Scenarios**:
- **Script not executing**: Reference `references/debugging.md` (lines 47-50) - Troubleshooting checklist
- **Missing shebang or path errors**: Reference `references/components/hooks.md` (line 70) for template, `references/manifest-schema.md` (line 87) for `${CLAUDE_PLUGIN_ROOT}` usage

### 5. Metadata & Configuration Validation

**When to use**: Validating plugin.json, frontmatter, version management, and configuration files.

**Scenarios**:
- **plugin.json validation**: Reference `references/manifest-schema.md`
- **Frontmatter validation**: Reference component-specific files in `references/components/`
- **Version management**: Reference `references/debugging.md` (lines 96-120)

### 6. Debugging & Troubleshooting

**When to use**: Diagnosing plugin loading failures, component discovery issues, hook/MCP problems, or runtime errors.

**Scenarios**:
- **Plugin loading, component discovery, hooks, MCP issues**: Reference `references/debugging.md` - See specific sections for each issue type

### 7. Workflow & Documentation

**When to use**: Using CLI commands, maintaining documentation, or following development workflows.

**Scenarios**:
- **CLI commands**: Reference `references/cli-commands.md`
- **Documentation/TodoWrite**: Reference `references/todowrite-usage.md`

Load specific reference files as needed to provide detailed validation logic without overwhelming the context. Each reference file contains comprehensive patterns, examples, and anti-patterns for its specific domain.
