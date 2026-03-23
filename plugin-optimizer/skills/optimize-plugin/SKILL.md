---
name: optimize-plugin
description: This skill should be used when the user asks to "validate a plugin", "optimize plugin", "check plugin quality", "review plugin structure", or "run plugin optimizer".
argument-hint: <plugin-path>
user-invocable: true
allowed-tools: ["Read", "Glob", "Bash(realpath:*)", "Bash(python3:*)", "AskUserQuestion", "TaskCreate", "TaskUpdate"]
---

# Plugin Optimization

Execute plugin validation and optimization workflow. **Target:** $ARGUMENTS

## Background Knowledge

Load `plugin-optimizer:plugin-best-practices` skill using the Skill tool for component templates, tool invocation rules, and type classification.

## Phase 1: Discovery & Validation

**Goal**: Validate structure and detect issues. Orchestrator MUST NOT apply fixes.

**Actions**:
1. Resolve path with `realpath` and verify existence
2. Validate `.claude-plugin/plugin.json` exists
3. Find component directories: `commands/`, `agents/`, `skills/`, `hooks/`
4. Validate components against `${CLAUDE_PLUGIN_ROOT}/examples/` templates
5. Assess architecture: if `commands/` exists with `.md` files, use `AskUserQuestion` tool to ask about migrating to skills structure
6. Run validation: `python3 ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin.py "$TARGET"`
   - Options: `--check=structure,manifest,frontmatter,tools,tokens`
   - JSON output: `--json`
   - Verbose: `-v, --verbose`
7. Compile issues by severity (Critical, Warning, Info)

## Phase 2: Agent-Based Optimization

**Goal**: Launch agent to apply ALL fixes. Orchestrator does NOT make fixes directly.

**Condition**: Always execute.

**Actions**:
1. Launch `plugin-optimizer:plugin-optimizer` agent with the following prompt content:
   - Target plugin path (absolute path from Phase 1)
   - Validation console output (issues list from Phase 1)
   - Template validation results
   - User decisions (migration choice if applicable)
   - INSTRUCTION: Analyze the validation output to identify issues
2. Agent autonomously applies fixes (MUST use `AskUserQuestion` tool before applying template fixes, presenting violations with specific examples and before/after comparison)
3. Agent increments version in `.claude-plugin/plugin.json` after fixes:
   - Patch (x.y.Z+1): Bug fixes
   - Minor (x.Y+1.0): New components
   - Major (X+1.0.0): Breaking changes
4. Wait for agent to complete

**Path Reference Rules**:
- Same directory: Use relative paths (`./reference.md`)
- Outside directory: Use `${CLAUDE_PLUGIN_ROOT}` paths
- Component templates: See `${CLAUDE_PLUGIN_ROOT}/examples/`

**Redundancy & Efficiency**:
- Redundancy: Allow strategic repetition of critical content (MUST/SHOULD requirements). Favor concise restatement.
- Efficiency: Agent detects if tasks need Agent Teams (Parallelizable > 5 files, Multi-domain).

## Phase 3: Verification & Deliverables

**Goal**: Verify fixes, generate report, and update documentation.

**Actions**:
1. Execute validation script: `python3 ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin.py "$TARGET"`
2. Analyze results: compare with Phase 1 findings, confirm critical issues resolved
3. If critical issues remain, resume agent execution
4. Generate final validation report using template below
5. Update `README.md` to reflect current state (metadata, directory structure, usage instructions; do not append version history log)

## Validation Report Template

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
- Token budgets validation: [PASS/FAIL]

### Token Budget Analysis
- Skills analyzed: [count]
- Tier 1 (Metadata ~50): [OK count], [WARNING count]
- Tier 2 (SKILL.md ~500): [OK count], [WARNING count], [CRITICAL count]
- Tier 3 (References 2000+ typical): [total tokens]

### Component Inventory
- Commands: [count] found, [count] valid
- Agents: [count] found, [count] valid
- Skills: [count] found, [count] valid

### Remaining Issues
[Issues that couldn't be auto-fixed with explanations]

### Overall Assessment
[PASS/FAIL] - [Detailed reasoning]
```