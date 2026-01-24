---
name: optimize-plugin
description: This skill should be used when the user asks to "validate a plugin", "optimize plugin", "check plugin quality", or mentions plugin optimization and validation tasks.
argument-hint: <plugin-path>
user-invocable: true
allowed-tools: ["Read", "Glob", "Bash(realpath *)", "Bash(bash:*)", "Task", "AskUserQuestion"]
---

# Plugin Optimization

Comprehensive plugin validation and optimization workflow. Orchestrate validation through specialized agent that applies fixes based on `plugin-optimizer:plugin-best-practices` skill.

**Target plugin:** $ARGUMENTS

## Core Principles

- **Strict Phases**: Follow phases sequentially without skipping steps
- **User Confirmation**: Ask for user input and decisions where specified
- **Agent-Based Optimization**: Delegate all fixes to specialized agent
- **Reference-Driven**: Agent must consult appropriate `references/` files for each issue category

---

## Phase 1: Discovery & Validation

**Goal**: Validate plugin structure and detect all issues. Orchestrator MUST NOT apply fixes in this phase.

**Orchestrator Role**: Run validation scripts, ask user for decisions, compile issues list.

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

**Critical**: Orchestrator MUST NOT fix any issues. All fixes delegated to agent in Phase 2.

---

## Phase 2: Agent-Based Optimization

**Goal**: Launch agent to apply ALL fixes based on issues found in Phase 1.

**Actions**:
1. Launch `plugin-optimizer:plugin-optimizer` agent
2. Provide context:
   - Target plugin absolute path
   - Validation issues from Phase 1 (organized by severity)
   - User decisions (migration choice if applicable)
3. Wait for agent to complete optimization workflow
4. Receive list of applied fixes from agent

**Critical**: Launch agent ONCE with all context. Orchestrator MUST NOT make fixes in main session.

---

## Phase 3: Redundancy & Quality Analysis

**Goal**: Identify and fix content duplication, validate documentation quality.

**Actions**:
1. Resume SAME agent from Phase 2 (preserve context)
2. Agent performs redundancy analysis and quality review
3. Agent asks for user confirmation before applying fixes
4. Receive report of redundancy and quality improvements

**Critical**: Resume agent from Phase 2. Orchestrator MUST NOT spawn new agent.

---

## Phase 4: Final Verification

**Goal**: Re-run validation scripts to verify all fixes were applied correctly.

**Orchestrator Role**: You take back control. Run validation suite ONCE to verify.

**Actions**:
1. **Re-run Validation Suite** using Bash tool:
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-file-patterns.sh "$TARGET"`
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin-json.sh "$TARGET"`
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-frontmatter.sh "$TARGET"`
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-tool-invocations.sh "$TARGET"`
2. **Compare Results**: Compare with Phase 1 validation to confirm critical issues resolved
3. **Document Remaining Issues**: Note any issues that remain (design decisions, optional improvements)

**Critical**: Orchestrator MUST NOT attempt fixes in this phase. Only verify and document.

---

## Phase 5: Summary Report

**Goal**: Generate comprehensive validation report with all findings and fixes.

**Orchestrator Role**: Synthesize all phase results into final report.

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
