---
name: optimize-plugin
description: This skill should be used when the user asks to "validate a plugin", "optimize plugin", "check plugin quality", "review plugin structure", or mentions plugin optimization and validation tasks.
argument-hint: <plugin-path>
user-invocable: true
allowed-tools: ["Read", "Glob", "Bash(realpath *)", "Bash(bash:*)", "Task", "AskUserQuestion"]
---

# Plugin Optimization

Execute plugin validation and optimization workflow through specialized agent.

**Target plugin:** $ARGUMENTS

---

## Phase 1: Discovery & Validation

**Goal**: Validate plugin structure and detect all issues. Orchestrator MUST NOT apply fixes in this phase.

**Actions**:
1. **Path Resolution**: Use `realpath` to resolve absolute path from `$ARGUMENTS`
2. **Existence Check**: Verify the resolved path exists
3. **Directory Structure Validation**:
   - Check for `.claude-plugin/plugin.json` manifest (required)
   - Find component directories: `commands/`, `agents/`, `skills/`, `hooks/`
   - Verify auto-discovery configuration
   - Report missing directories or files (MUST NOT create them)
4. **Modern Architecture Assessment**:
   - If `commands/` directory exists with `.md` files:
     - Ask user: "This plugin uses legacy `commands/` structure. Modern best practice recommends `skills/` for better modularity. Would you like to migrate commands to skills structure?"
     - Options: "Yes, migrate to skills" / "No, keep commands as-is"
     - Record user decision for Phase 2
5. **Execute Validation Suite** - Run all scripts using Bash tool:
   - **Structure**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-file-patterns.sh "$TARGET"`
   - **Manifest**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin-json.sh "$TARGET"`
   - **Components**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-frontmatter.sh "$TARGET"`
   - **Anti-Patterns**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-tool-invocations.sh "$TARGET"`
6. **Analysis**: Review output from all scripts and compile comprehensive list of issues by severity:
   - Critical issues (MUST fix)
   - Warnings (SHOULD fix)
   - Info (MAY improve)

---

## Phase 2: Agent-Based Optimization

**Goal**: Launch agent to apply ALL fixes based on issues found in Phase 1.

**Actions**:
1. Launch `plugin-optimizer:plugin-optimizer` agent
2. Provide context:
   - Target plugin absolute path
   - Validation issues from Phase 1 (organized by severity)
   - User decisions (migration choice if applicable)
   - Current workflow phase: "initial fixes"
   - **Path reference validation rules**:
     - Files within same skill/agent directory: Use relative paths (e.g., `./reference.md`, `examples/example.md`)
     - Files outside skill/agent directory: MUST use `${CLAUDE_PLUGIN_ROOT}` paths (e.g., `${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh`, `${CLAUDE_PLUGIN_ROOT}/lib/utils.sh`)
     - Verify all file references follow correct path pattern
   - **Component templates** (for reference when creating/fixing components):
     
     **Instruction-Type Skill** (`user-invocable: true` → `commands`):
     - Imperative voice: "Load...", "Create...", "Analyze..."
     - Structure: Phase-based workflow with Actions lists
     - Example:
       ```markdown
       ## Phase 1: Preparation
       **Actions**:
       1. Gather required input
       2. Load necessary knowledge skills
       3. Validate preconditions
       ```
     
     **Knowledge-Type Skill** (`user-invocable: false` → `skills`):
     - Declarative voice: "Commands are...", "Skills provide...", "Use when..."
     - Structure: Topic-based sections with rules and best practices
     - Example:
       ```markdown
       ## Core Concepts
       Components are modular units that extend Claude's capabilities.
       
       **Best Practices**:
       - Components MUST follow naming conventions
       - Components SHOULD have clear responsibilities
       ```
     
     **Agent**:
     - Descriptive voice: "You are an expert [domain] specialist..."
     - Structure: Core Responsibilities, Knowledge Base, Approach sections
     - Example:
       ```markdown
       You are an expert [domain] specialist for [context].

       ## Knowledge Base
       The loaded `[plugin-name]:[skill-name]` skill provides:
       - [Domain] standards and validation rules

       ## Core Responsibilities
       1. **Analyze [inputs]** to understand requirements
       2. **Apply [expertise]** based on domain knowledge
       3. **Generate [outputs]** meeting quality criteria

       ## Approach
       - **Autonomous**: Make decisions based on expertise
       - **Comprehensive**: Track all actions and results
       ```
3. Wait for agent to complete optimization workflow
4. Receive list of applied fixes from agent
5. **Update Plugin Documentation**:
   - Update README.md with current plugin structure, components, and usage
   - Ensure README reflects any migrations or structural changes
6. **Update Plugin Version**:
   - Increment version in `.claude-plugin/plugin.json` based on extent of changes:
     - Patch (x.y.Z+1): Bug fixes, minor corrections
     - Minor (x.Y+1.0): New components, feature additions
     - Major (X+1.0.0): Breaking changes, major migrations

**Critical**: Launch agent ONCE with all context. Orchestrator MUST NOT make fixes in main session.

---

## Phase 3: Redundancy & Quality Analysis

**Goal**: Identify and fix content duplication, validate documentation quality.

**Actions**:
1. Resume SAME agent from Phase 2 (preserve context)
2. Agent performs redundancy analysis and quality review:
   - Identify true duplication (verbatim repetition without purpose)
   - **Allow strategic repetition** of critical content: core validation rules, MUST/SHOULD requirements, safety constraints, key workflow steps that must not be missed, critical decision points or constraints, templates, and examples
   - Distinguish progressive disclosure (summary → detail) from redundancy
3. Agent asks for user confirmation before applying fixes
4. Receive report of redundancy and quality improvements

---

## Phase 4: Final Verification

**Goal**: Re-run validation scripts to verify all fixes were applied correctly.

**Actions**:
1. **Re-run Validation Suite** using Bash tool:
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-file-patterns.sh "$TARGET"`
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin-json.sh "$TARGET"`
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-frontmatter.sh "$TARGET"`
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-tool-invocations.sh "$TARGET"`
2. **Compare Results**: Compare with Phase 1 validation to confirm critical issues resolved
3. **Fix Remaining Issues**: If validation reveals new or unresolved issues:
   - Resume agent from Phase 2-3 (preserve context)
   - Provide remaining issues from verification results
   - Wait for agent to apply additional fixes
   - Receive updated fix report
4. **Document Remaining Issues**: Note any issues that remain (design decisions, optional improvements)

---

## Phase 5: Summary Report

**Goal**: Generate comprehensive validation report with all findings and fixes.

**Actions**:
1. Synthesize all phase results into final report
2. Use report format template below
3. Include: issues detected, fixes applied, verification results, component inventory, remaining issues, recommendations
4. Provide overall assessment (PASS/FAIL) with detailed reasoning

**Report Format**:

```markdown
## Plugin Validation Report

### Plugin: [name]
Location: [absolute-path]
Version: [old] → [new]

### Summary
[Overall assessment with key statistics]

### Phase 1: Issues Detected
#### Critical ([count])
- `file/path` - [Issue description]

#### Warnings ([count])
- `file/path` - [Issue description]

#### Info ([count])
- `file/path` - [Suggestion]

### Phase 2-3: Fixes Applied
#### Structure Fixes
- [Fix description]

#### Manifest Fixes
- [Fix description]

#### Component Fixes
- [Fix description]

#### Migration Performed
- [Details if commands migrated to skills]

#### Redundancy Fixes
- [Consolidations applied]

#### Quality Improvements
- [Documentation updates]

### Phase 4: Verification Results
- Structure validation: [PASS/FAIL]
- Manifest validation: [PASS/FAIL]
- Component validation: [PASS/FAIL]
- Tool patterns validation: [PASS/FAIL]

### Component Inventory
- Commands: [count] found, [count] valid
- Agents: [count] found, [count] valid
- Skills: [count] found, [count] valid
- Hooks: [present/absent], [valid/invalid]
- MCP Servers: [count] configured

### Remaining Issues
[Issues that couldn't be auto-fixed or are design decisions with explanations]

### Positive Findings
- [What's implemented well]

### Recommendations
1. [Priority recommendation for manual follow-up]
2. [Additional suggestions]

### Overall Assessment
[PASS/FAIL] - [Detailed reasoning based on validation results]
```
