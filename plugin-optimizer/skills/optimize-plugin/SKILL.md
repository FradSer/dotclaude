---
name: optimize-plugin
description: This skill should be used when the user asks to "validate a plugin", "optimize plugin", "check plugin quality", "review plugin structure", or mentions plugin optimization and validation tasks.
argument-hint: <plugin-path>
user-invocable: true
allowed-tools: ["Read", "Glob", "Bash(realpath *)", "Bash(bash:*)", "Task", "AskUserQuestion", "TaskCreate", "TaskUpdate"]
---

# Plugin Optimization

Execute plugin validation and optimization workflow. **Target:** $ARGUMENTS

## Background Knowledge

**Template Compliance**: Components MUST conform to templates in `${CLAUDE_PLUGIN_ROOT}/examples/`. See `references/template-validation.md` for complete requirements (instruction-type/knowledge-type skills, agents).

**Tool Patterns**: See `references/tool-patterns.md` for invocation styles. Key: Skill/AskUserQuestion/TaskCreate require explicit "Use [tool] tool" phrasing.

## Phase 1: Discovery & Validation

**Goal**: Validate structure and detect issues. Orchestrator MUST NOT apply fixes.

**Actions**:
1. Resolve path with `realpath` and verify existence
2. Validate `.claude-plugin/plugin.json` exists
3. Validate components against `${CLAUDE_PLUGIN_ROOT}/examples/` templates
4. Assess architecture (ask about command migration if needed)
5. Run validation: `python3 ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin.py "$TARGET"`
6. Compile issues by severity (Critical, Warning, Info)
7. See `references/discovery-validation.md` for detailed validation rules and options.

## Phase 2: Agent-Based Optimization

**Goal**: Launch agent to apply ALL fixes. Orchestrator does NOT make fixes directly.

**Condition**: Always execute.

**Actions**:
1. Launch `plugin-optimizer:plugin-optimizer` agent with the following prompt content:
   - Target plugin path (absolute path from Phase 1)
   - Any user decisions from architecture assessment
   - INSTRUCTION: Analyze the validation console output provided in the context to identify issues.
2. Agent autonomously applies fixes (uses AskUserQuestion for template fix approvals)
3. Agent increments version in `.claude-plugin/plugin.json` after fixes (patch: fixes/optimizations, minor: new components, major: breaking changes)
4. See `references/execution-details.md` for context rules and fix requirements.

## Phase 3: Verification & Deliverables

**Goal**: Verify fixes, generate report, and update documentation.

**Actions**:
1. Re-run all validation scripts from Phase 1
2. Compare results with initial findings (resume agent if critical issues remain)
3. Generate complete validation report
4. Update README.md to accurately reflect current plugin state
5. See `./references/deliverables.md` for detailed steps and report format
