# Discovery & Validation Details

Reference for Phase 1 of the optimization workflow.

## Path Resolution
- Use `realpath` to resolve absolute path from `$ARGUMENTS`
- Verify the resolved path exists

## Directory Structure
- Check for `.claude-plugin/plugin.json` manifest (required)
- Find component directories: `commands/`, `agents/`, `skills/`, `hooks/`
- Report missing directories or files (MUST NOT create them)

## Component Templates
- Read complete file (frontmatter + body) for each component
- Validate against templates in `${CLAUDE_PLUGIN_ROOT}/examples/`
- See `./template-validation.md` for detailed rules
- Report ALL template violations as CRITICAL issues

## Modern Architecture
If `commands/` directory exists with `.md` files:
- Use `AskUserQuestion` tool to ask about migrating to skills structure
- Record user decision for Phase 2

## Validation Script
Run the unified validation script:
```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin.py "$TARGET"
```
**Output is captured in console and passed to Phase 2.**

### Options
- `--check=structure,manifest,frontmatter,tools,tokens` — Run specific validators
- `--json` — Output results as JSON
- `-v, --verbose` — Detailed output
