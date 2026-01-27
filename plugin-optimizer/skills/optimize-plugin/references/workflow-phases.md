# Workflow Phase Details

Complete reference for the 4-phase optimization workflow.

## Phase 1: Discovery & Validation

### Path Resolution & Verification
1. Use `realpath` to resolve absolute path from `$ARGUMENTS`
2. Verify the resolved path exists

### Directory Structure Validation
- Check for `.claude-plugin/plugin.json` manifest (required)
- Find component directories: `commands/`, `agents/`, `skills/`, `hooks/`
- Report missing directories or files (MUST NOT create them)

### Component Template Validation
- Read complete file (frontmatter + body) for each component
- Validate against templates in `${CLAUDE_PLUGIN_ROOT}/examples/`
- See `./template-validation.md` for detailed validation rules
- Cross-check `plugin.json` declarations match component types
- Report ALL template violations as CRITICAL issues

### Modern Architecture Assessment
If `commands/` directory exists with `.md` files:
- Use `AskUserQuestion` tool to ask about migrating to skills structure
- Record user decision for Phase 2

### Validation Scripts

Run all validation scripts:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-file-patterns.sh "$TARGET"
bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin-json.sh "$TARGET"
bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-frontmatter.sh "$TARGET"
bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-tool-invocations.sh "$TARGET"
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/count-tokens.py "$TARGET" --all
```

### Analysis
Compile issues by severity (Critical, Warnings, Info)

---

## Phase 2: Agent-Based Optimization

### Agent Context Requirements

Launch `plugin-optimizer:plugin-optimizer` agent with:
- Target plugin absolute path
- Validation issues from Phase 1 (organized by severity)
- Template validation results (component violations and recommended fixes)
- User decisions (migration choice if applicable)

### Path Reference Rules
- Same directory: Use relative paths (`./reference.md`)
- Outside directory: Use `${CLAUDE_PLUGIN_ROOT}` paths
- Component templates: See `${CLAUDE_PLUGIN_ROOT}/examples/`

### Template Fix Requirements
- Agent MUST use `AskUserQuestion` tool before applying template fixes
- Present detected violations with specific examples
- Show before/after comparison for structure fixes

### Redundancy Analysis
- Allow strategic repetition of critical content (MUST/SHOULD requirements, templates, examples)
- Favor concise restatement over verbatim duplication

### Post-Agent Actions
1. Wait for agent to complete optimization tasks
2. Receive fix report from agent
3. Update plugin version in `.claude-plugin/plugin.json`:
   - Patch (x.y.Z+1): Bug fixes
   - Minor (x.Y+1.0): New components
   - Major (X+1.0.0): Breaking changes

**Critical**: Launch agent ONCE with all context. Orchestrator MUST NOT make fixes directly.

---

## Phase 3: Final Verification

### Re-run Validation Suite

Execute all validation scripts again:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-file-patterns.sh "$TARGET"
bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin-json.sh "$TARGET"
bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-frontmatter.sh "$TARGET"
bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-tool-invocations.sh "$TARGET"
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/count-tokens.py "$TARGET" --all
```

### Results Analysis
1. Compare results with Phase 1 findings
2. Confirm critical issues resolved
3. If issues remain, resume agent with remaining issues
4. Document remaining issues (design decisions or optional improvements)

---

## Phase 4: Final Deliverables

### Comprehensive Report Generation
1. Synthesize results from all validation and optimization phases
2. Include: issues detected, fixes applied, verification outcomes, component inventory
3. Provide overall assessment (PASS/FAIL) with clear reasoning
4. See `./report-template.md` for complete report format

### README Documentation Update
1. Read current README.md structure
2. Generate updated content reflecting current plugin state:
   - Plugin metadata from `plugin.json` (name, version, description)
   - Accurate directory structure and component inventory
   - Installation instructions and usage examples
3. Replace existing README.md with current documentation
4. Ensure no version history is appended (users reference git log for history)
