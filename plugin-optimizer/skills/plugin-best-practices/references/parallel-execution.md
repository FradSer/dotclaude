# Parallel Agent Execution

Guide for launching multiple agents simultaneously for independent analysis.

## When to Use Parallel Execution

Parallel execution applies when tasks are independent and results can be merged afterward.

## Request Patterns

### Explicit Parallel Request

```markdown
Launch all agents simultaneously:
- `domain-analyzer` agent
- `quality-validator` agent
- `format-checker` agent
```

### "In Parallel" Phrasing

```markdown
Launch 3 parallel agents to process different aspects independently
```

## Best Practices

- "parallel" or "simultaneously" appears explicitly in the request
- Descriptive style names the agent and intent
- Consolidation merges findings and resolves conflicts

## Common Pattern

```markdown
1. Sequential setup (if needed)
2. Launch specialized analyses in parallel:
   - `aspect-one-analyzer` agent — first dimension
   - `aspect-two-validator` agent — second dimension
   - `aspect-three-checker` agent — third dimension
3. Consolidate results and present unified output
```
