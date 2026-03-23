# Superpower Loop Patterns

## Completion Promise Design

The completion promise is the exit condition for a Superpower Loop. The Stop hook scans the last assistant turn for `<promise>TEXT</promise>` and exits on exact match.

### Mechanics

- **Exact string match** — `"DONE"` and `"Done"` are different promises
- **Whitespace normalized** — internal whitespace collapsed to single spaces
- **First tag wins** — only one `<promise>` tag is matched
- **Multi-word promises need quotes** when passing via `--completion-promise`

### Superpowers Promise Conventions

| Skill | Promise | TRUE When |
|-------|---------|-----------|
| brainstorming | `BRAINSTORMING_COMPLETE` | All 4 phases done, design committed |
| writing-plans | `PLAN_COMPLETE` | All phases done, plan committed |
| executing-plans | `EXECUTION_COMPLETE` | All tasks executed, verified, committed |

### Integrity Rules

**MUST NOT** output a false promise — even when stuck, believing task is impossible, or wanting to exit. The loop continues until the promise is genuinely true. Use `--max-iterations` as a safety net.

### Multiple Outcomes

Use a single promise covering all exit paths; encode the outcome in prose before the tag:

```
Report either "All tests pass" or "Blocked after N attempts — see notes"
Then output <promise>TASK_123_COMPLETE</promise> in either case.
```

## Prompt Patterns

Effective loop prompts have four properties: clear completion criteria, incremental goals, self-correction instructions, and escape hatches.

### Clear Completion Criteria

```
Build a REST API for todos.
Requirements:
- CRUD endpoints, input validation, 80% test coverage, README
Output <promise>COMPLETE</promise> when all requirements met and tests pass.
```

### Incremental Goals

Break large tasks into phases within the prompt for measurable progress each iteration.

### Self-Correction

```
Implement feature X following TDD:
1. Write failing test (Red)
2. Implement minimal code to pass (Green)
3. Run tests — if any fail, debug and fix
4. Refactor while keeping tests green
Output <promise>COMPLETE</promise> when all tests green.
```

### Escape Hatches

Always use `--max-iterations`. For long loops, add fallback instructions:

```
If after 15 iterations still incomplete:
- Document what is blocking
- List attempts and why they failed
- Suggest 2-3 alternatives
```

### Usage

```bash
# Simple prompts:
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh" "Build a REST API" \
  --completion-promise "COMPLETE" --max-iterations 20

# Complex prompts (special characters, code blocks):
cat > ".claude/task-prompt.tmp.md" <<'PROMPT_EOF'
## Task: Complex task with special characters
...
PROMPT_EOF
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh" \
  --prompt-file ".claude/task-prompt.tmp.md" \
  --completion-promise "COMPLETE" --max-iterations 20
```
