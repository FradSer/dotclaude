---
name: optimize-plugin
description: This skill should be used when the user asks to "validate a plugin", "optimize plugin", "check plugin quality", "review plugin structure", or mentions plugin optimization and validation tasks.
argument-hint: <plugin-path>
user-invocable: true
allowed-tools: ["Read", "Glob", "Bash(realpath *)", "Bash(bash:*)", "Task", "AskUserQuestion", "TodoWrite"]
---

# Plugin Optimization

Execute plugin validation and optimization workflow through specialized agent.

**Target plugin:** $ARGUMENTS

---

## Phase 0: Initialization

**Goal**: Set up task tracking for the optimization workflow.

**Actions**:
1. Use TodoWrite tool to create task list with all phases:
   - **Phase 1: Discovery & Validation** - Validate plugin structure and detect all issues
   - **Phase 2: Agent-Based Optimization & Quality Analysis** - Launch agent to apply fixes and perform quality improvements
   - **Phase 3: Final Verification** - Re-run validation scripts to verify all fixes
   - **Phase 4: Summary Report** - Generate comprehensive validation report

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
4. **Skill Type Classification & Manifest Validation**:
   - For each SKILL.md file, classify it using the checklist below (Instruction-type vs Knowledge-type)
   - Validate plugin.json declarations match skill types
   - Report mismatches as CRITICAL issues
   - Record classification results for Phase 2 agent
5. **Modern Architecture Assessment**:
   - If `commands/` directory exists with `.md` files:
     - Ask user about migrating to skills structure
     - Record user decision for Phase 2
6. **Execute Validation Suite** - Run all scripts:
   - **Structure**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-file-patterns.sh "$TARGET"`
   - **Manifest**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin-json.sh "$TARGET"`
   - **Components**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-frontmatter.sh "$TARGET"`
   - **Anti-Patterns**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-tool-invocations.sh "$TARGET"`
7. **Analysis**: Compile comprehensive list of issues by severity:
   - Critical issues (MUST fix)
   - Warnings (SHOULD fix)
   - Info (MAY improve)

### Skill Type Classification

Classify each `./skills/**/SKILL.md` as Instruction-type vs Knowledge-type, then verify the `plugin.json` declaration matches.

1. Read the complete file (frontmatter + body) so you can compare metadata vs writing style
2. Check frontmatter `user-invocable`:
   - `user-invocable: true` -> Instruction-type (preliminary)
   - `user-invocable: false` -> Knowledge-type (preliminary)
   - Missing -> Continue with content analysis
3. Determine the natural writing style (pick the best match):

Imperative indicators (Instruction-type):
- Imperative verbs: "Load", "Create", "Execute", "Analyze", "Generate", "Launch"
- Phase/step structure: "## Phase 1", "## Step 1", "**Actions**:"
- Workflow sequences: numbered action lists, linear process flow
- Direct constraints: "MUST NOT apply fixes", "Wait for agent"

Declarative indicators (Knowledge-type):
- Declarative verbs: "is", "are", "provides", "defines", "describes"
- Topic-based structure: "## Core Concepts", "## Best Practices", "## Patterns"
- Reference content: definitions, tables, examples without an execution sequence
- Teaching tone: "Skills are...", "Use when...", "Components MUST..."

4. Flag CRITICAL mismatches:
   - Frontmatter vs content conflict -> CRITICAL
   - Content style implies Instruction-type but missing phase structure -> CRITICAL template violation
5. Validate `plugin.json` declaration:
   - Instruction-type MUST be in `commands`
   - Knowledge-type MUST be in `skills`
6. Record results for Phase 2 agent:
   - Skill path, detected type, `user-invocable` value, manifest location, style indicators, recommended fix

Mismatch examples:
```text
Skill `./skills/foo/SKILL.md` has `user-invocable: true` but uses declarative style (suggests Knowledge-type)
Instruction-type skill `./skills/bar/` declared in `skills`, MUST move to `commands`
Skill `./skills/baz/` uses imperative voice but missing phase structure (should follow Instruction-type template)
```

Quick reference:

| Type | user-invocable | Voice | Structure | Declared in |
|------|----------------|-------|-----------|-------------|
| Instruction | `true` | Imperative | Phase-based | `commands` |
| Knowledge | `false` | Declarative | Topic-based | `skills` |

---

## Phase 2: Agent-Based Optimization & Quality Analysis

**Goal**: Launch agent to apply ALL fixes based on issues found in Phase 1, including redundancy and quality improvements.

**Actions**:
1. Launch `plugin-optimizer:plugin-optimizer` agent
2. Provide context:
   - Target plugin absolute path
   - Validation issues from Phase 1 (organized by severity)
   - User decisions (migration choice if applicable)
   - Current workflow phase: "optimization and quality analysis"
   - **Path reference validation rules**:
     - Files within same skill/agent directory: Use relative paths (e.g., `./reference.md`, `examples/example.md`)
     - Files outside skill/agent directory: MUST use `${CLAUDE_PLUGIN_ROOT}` paths
     - Verify all file references follow correct path pattern
   - **Component templates**: See `${CLAUDE_PLUGIN_ROOT}/examples/` for complete templates and validation checklist
   - **Redundancy analysis requirements**:
     - Identify true duplication (verbatim repetition without purpose)
     - **Allow strategic repetition** of critical content: core validation rules, MUST/SHOULD requirements, safety constraints, key workflow steps that must not be missed, critical decision points or constraints, templates, and examples
     - Distinguish progressive disclosure (summary → detail) from redundancy
3. Agent performs optimization workflow:
   - Apply all fixes based on Phase 1 issues
   - Perform redundancy analysis and quality review
   - Ask for user confirmation before applying redundancy fixes
4. Wait for agent to complete all optimization tasks
5. Receive comprehensive list of applied fixes from agent (including redundancy and quality improvements)
6. **Update Plugin Documentation**:
   - Update README.md with current plugin structure, components, and usage
   - Ensure README reflects any migrations or structural changes
7. **Update Plugin Version**:
   - Increment version in `.claude-plugin/plugin.json` based on extent of changes:
     - Patch (x.y.Z+1): Bug fixes, minor corrections
     - Minor (x.Y+1.0): New components, feature additions
     - Major (X+1.0.0): Breaking changes, major migrations

**Critical**: Launch agent ONCE with all context. Orchestrator MUST NOT make fixes in main session.

---

## Phase 3: Final Verification

**Goal**: Re-run validation scripts to verify all fixes were applied correctly.

**Actions**:
1. **Re-run Validation Suite** using Bash tool:
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-file-patterns.sh "$TARGET"`
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin-json.sh "$TARGET"`
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-frontmatter.sh "$TARGET"`
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-tool-invocations.sh "$TARGET"`
2. **Compare Results**: Compare with Phase 1 validation to confirm critical issues resolved
3. **Fix Remaining Issues**: If validation reveals new or unresolved issues:
   - Resume agent from Phase 2 (preserve context)
   - Provide remaining issues from verification results
   - Wait for agent to apply additional fixes
   - Receive updated fix report
4. **Document Remaining Issues**: Note any issues that remain (design decisions, optional improvements)

---

## Phase 4: Summary Report

**Goal**: Generate comprehensive validation report with all findings and fixes.

**Actions**:
1. Synthesize all phase results into final report
2. Use the report format below
3. Include: issues detected, fixes applied, verification results, component inventory, remaining issues, recommendations
4. Provide overall assessment (PASS/FAIL) with detailed reasoning

### Report Template

```markdown
## Plugin Validation Report

### Plugin: [name]
Location: [absolute-path]
Version: [old] -> [new]

### Summary
[Overall assessment with key statistics]

### Phase 1: Issues Detected
#### Critical ([count])
- `file/path` - [Issue description]

#### Warnings ([count])
- `file/path` - [Issue description]

#### Info ([count])
- `file/path` - [Suggestion]

### Phase 2: Fixes Applied
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

Section guidelines (keep these while writing, omit them from the final report if the user asks for brevity):
- Summary: 2-3 sentences, include counts and whether production-ready
- Issues: sort Critical -> Warnings -> Info, include line numbers when relevant
- Fixes: group by category, be concrete about changes
- Verification: report PASS/FAIL per script and compare vs Phase 1
- Inventory: counts for found vs valid per component type
- Remaining issues: explain why not fixed (blocker vs design), include manual next steps
