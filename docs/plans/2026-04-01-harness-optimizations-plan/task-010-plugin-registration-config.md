# Task 010: Register evaluator agent and validate plugin

**depends-on**: task-004, task-007, task-008, task-009

## Description

Update `superpowers/.claude-plugin/plugin.json` to register the evaluator agent for auto-discovery, bump the plugin version, and run full plugin validation to confirm all new and modified files pass structural and token budget checks.

## Execution Context

**Task Number**: 010 of 10
**Phase**: Finalization
**Prerequisites**: Tasks 004 (agent exists), 007 (SKILL.md updated), 008 (playbook updated), 009 (escalation updated)

## BDD Scenario

```gherkin
Scenario: Evaluator agent registered in plugin.json
  Given the evaluator agent exists at superpowers/agents/evaluator.md
  When plugin.json is updated
  Then the "agents" array is added (or extended) with "./agents/evaluator.md"
  And the plugin version is bumped (patch increment from 2.1.0)

Scenario: Plugin passes full validation
  Given all new files are created and existing files are modified
  When validate-plugin.py runs against superpowers/
  Then it exits with code 0
  And no MUST violations are found
  And token budgets are within limits (evaluator agent body under 3k tokens)
```

**Spec Source**: `../2026-03-31-harness-optimizations-design/harness-optimizations-requirements.md` (Section 2.2, 2.3)

## Files to Modify/Create

- Modify: `superpowers/.claude-plugin/plugin.json`

## Steps

### Step 1: Read current plugin.json
- Understand current structure (commands, skills, hooks)
- Check if an "agents" key already exists

### Step 2: Update plugin.json
- Add `"agents": ["./agents/evaluator.md"]` to the manifest
- Bump version from `2.1.0` to `2.2.0` (minor bump for new feature)
- Do NOT modify existing commands, skills, or hooks entries

### Step 3: Sync marketplace version
- Update the superpowers entry in `.claude-plugin/marketplace.json` to match the new version

### Step 4: Run full plugin validation
- Run `python3 plugin-optimizer/scripts/validate-plugin.py superpowers/`
- Verify exit code 0
- Check for any MUST violations or token budget issues
- If validation fails, fix identified issues

## Verification Commands

```bash
# plugin.json contains agents entry
grep -q '"agents"' superpowers/.claude-plugin/plugin.json && \
grep -q "evaluator" superpowers/.claude-plugin/plugin.json && \
echo "PASS: evaluator registered"

# Version bumped
grep -q '"2.2.0"' superpowers/.claude-plugin/plugin.json && echo "PASS: version bumped"

# Full validation
python3 plugin-optimizer/scripts/validate-plugin.py superpowers/ && echo "PASS: validation passed"
```

## Success Criteria

- Evaluator agent registered in plugin.json `agents` array
- Plugin version bumped to 2.2.0
- Marketplace.json version synced
- Full plugin validation passes (exit code 0)
- No MUST violations
- Token budgets within limits
