# Agent Execution Details

Reference for Phase 2 (Agent-Based Optimization).

## Agent Context
Launch `plugin-optimizer:plugin-optimizer` agent with:
- Target plugin absolute path
- **Validation console output** (issues list from Phase 1)
- Template validation results
- User decisions (migration choice if applicable)

## Path Reference Rules
- Same directory: Use relative paths (`./reference.md`)
- Outside directory: Use `${CLAUDE_PLUGIN_ROOT}` paths
- Component templates: See `${CLAUDE_PLUGIN_ROOT}/examples/`

## Template Fix Requirements
- Agent MUST use `AskUserQuestion` tool before applying template fixes
- Present detected violations with specific examples
- Show before/after comparison for structure fixes

## Redundancy & Efficiency
- **Redundancy**: Allow strategic repetition of critical content (MUST/SHOULD requirements). Favor concise restatement.
- **Efficiency**: Agent detects if tasks need **Agent Teams** (Parallelizable > 5 files, Multi-domain).

## Post-Agent Actions
1. Wait for agent to complete optimization tasks
2. Update plugin version in `.claude-plugin/plugin.json`:
   - Patch (x.y.Z+1): Bug fixes
   - Minor (x.Y+1.0): New components
   - Major (X+1.0.0): Breaking changes
