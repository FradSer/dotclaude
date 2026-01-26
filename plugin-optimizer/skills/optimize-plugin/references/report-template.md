# Validation Report Template

Use this template for Phase 4 summary reporting.

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
