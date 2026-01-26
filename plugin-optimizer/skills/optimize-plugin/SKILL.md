---
name: optimize-plugin
description: This skill should be used when the user asks to "validate a plugin", "optimize plugin", "check plugin quality", "review plugin structure", or mentions plugin optimization and validation tasks.
argument-hint: <plugin-path>
user-invocable: true
allowed-tools: ["Read", "Glob", "Bash(realpath *)", "Bash(bash:*)", "Task", "AskUserQuestion", "TaskCreate", "TaskUpdate"]
---

# Plugin Optimization

Execute plugin validation and optimization workflow through specialized agent.

**Target plugin:** $ARGUMENTS

## Background Knowledge

Tool invocation patterns for plugin content:

| Tool | Style | Correct Format |
|------|-------|----------------|
| Read, Write, Glob, Grep, Edit | Implicit | "Find files matching...", "Read each file..." |
| Bash | Implicit | "Run `git status`" |
| Task | Implicit | "Launch `plugin-name:agent-name` agent" |
| Skill | **Explicit** | "**Load `plugin-name:skill-name` skill** using the Skill tool" |
| AskUserQuestion | **Explicit** | "Use `AskUserQuestion` tool to [action]" |
| TaskCreate | **Explicit** | "**Use TaskCreate tool** to track" |

**Qualified names**: Plugin components MUST use `plugin-name:component-name` format.

---

## Initialization

**Goal**: Set up task tracking for the optimization workflow.

**Actions**:
1. **Use TaskCreate tool** to create task list with all phases:
   - **Phase 1: Discovery & Validation** - Validate plugin structure and detect all issues
   - **Phase 2: Agent-Based Optimization** - Launch agent to apply fixes and quality improvements
   - **Phase 3: Final Verification** - Re-run validation scripts to verify fixes
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
   - Report missing directories or files (MUST NOT create them)
4. **Component Template Validation**:
   - Read complete file (frontmatter + body) for each component
   - Validate against templates in `${CLAUDE_PLUGIN_ROOT}/examples/`
   - See `./references/template-validation.md` for detailed validation rules
   - Cross-check `plugin.json` declarations match component types
   - Report ALL template violations as CRITICAL issues
5. **Modern Architecture Assessment**:
   - If `commands/` directory exists with `.md` files:
     - Use `AskUserQuestion` tool to ask about migrating to skills structure
     - Record user decision for Phase 2
6. **Execute Validation Suite** - Run all scripts:
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-file-patterns.sh "$TARGET"`
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin-json.sh "$TARGET"`
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-frontmatter.sh "$TARGET"`
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-tool-invocations.sh "$TARGET"`
7. **Analysis**: Compile issues by severity (Critical, Warnings, Info)

---

## Phase 2: Agent-Based Optimization

**Goal**: Launch agent to apply ALL fixes based on Phase 1 issues.

**Actions**:
1. Launch `plugin-optimizer:plugin-optimizer` agent
2. Provide context:
   - Target plugin absolute path
   - Validation issues from Phase 1 (organized by severity)
   - Template validation results (component violations and recommended fixes)
   - User decisions (migration choice if applicable)
   - **Path reference rules**:
     - Same directory: Use relative paths (`./reference.md`)
     - Outside directory: Use `${CLAUDE_PLUGIN_ROOT}` paths
   - **Component templates**: See `${CLAUDE_PLUGIN_ROOT}/examples/`
   - **Template fix requirements**:
     - Agent MUST use `AskUserQuestion` tool before applying template fixes
     - Present detected violations with specific examples
     - Show before/after comparison for structure fixes
   - **Redundancy analysis**:
     - Allow strategic repetition of critical content (MUST/SHOULD requirements, templates, examples)
     - Favor concise restatement over verbatim duplication
3. Wait for agent to complete optimization tasks
4. Receive fix report from agent
5. **Update Plugin Documentation**: Update README.md with current structure
6. **Update Plugin Version** in `.claude-plugin/plugin.json`:
   - Patch (x.y.Z+1): Bug fixes
   - Minor (x.Y+1.0): New components
   - Major (X+1.0.0): Breaking changes

**Critical**: Launch agent ONCE with all context. Orchestrator MUST NOT make fixes directly.

---

## Phase 3: Final Verification

**Goal**: Re-run validation scripts to verify all fixes.

**Actions**:
1. **Re-run Validation Suite**:
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-file-patterns.sh "$TARGET"`
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin-json.sh "$TARGET"`
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-frontmatter.sh "$TARGET"`
   - `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-tool-invocations.sh "$TARGET"`
2. **Compare Results**: Confirm critical issues resolved
3. **Fix Remaining Issues**: If issues remain, resume agent with remaining issues
4. **Document Remaining Issues**: Note design decisions or optional improvements

---

## Phase 4: Summary Report

**Goal**: Generate comprehensive validation report.

**Actions**:
1. Synthesize all phase results into final report
2. Include: issues detected, fixes applied, verification results, component inventory
3. Provide overall assessment (PASS/FAIL) with reasoning

### Report Template

```markdown
## Plugin Validation Report

### Plugin: [name]
Location: [absolute-path]
Version: [old] -> [new]

### Summary
[2-3 sentences with key statistics]

### Phase 1: Issues Detected
#### Critical ([count])
- `file/path` - [Issue description]

#### Warnings ([count])
- `file/path` - [Issue description]

### Phase 2: Fixes Applied
#### Structure Fixes
- [Fix description]

#### Template Conformance
- **Agents**: [Count] validated, [count] fixed
- **Instruction-type Skills**: [Count] validated, [count] fixed
- **Knowledge-type Skills**: [Count] validated, [count] fixed

#### Redundancy Fixes
- [Consolidations applied]

### Phase 3: Verification Results
- Structure validation: [PASS/FAIL]
- Manifest validation: [PASS/FAIL]
- Component validation: [PASS/FAIL]
- Tool patterns validation: [PASS/FAIL]

### Component Inventory
- Commands: [count] found, [count] valid
- Agents: [count] found, [count] valid
- Skills: [count] found, [count] valid

### Remaining Issues
[Issues that couldn't be auto-fixed with explanations]

### Overall Assessment
[PASS/FAIL] - [Detailed reasoning]
```
