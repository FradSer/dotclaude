# Superpower Loop Prompt Patterns

Effective superpower loop prompts share four properties: clear completion criteria, incremental goals, self-correction instructions, and escape hatches.

## 1. Clear Completion Criteria

The loop only exits when Claude outputs the exact completion promise. The prompt must make the success condition unambiguous.

**Weak** — no verifiable end state:
```
Build a todo API and make it good.
```

**Strong** — specific, verifiable criteria:
```
Build a REST API for todos.

Requirements:
- CRUD endpoints: GET /todos, POST /todos, PUT /todos/:id, DELETE /todos/:id
- Input validation on all write operations
- Test coverage above 80%
- README with API docs

Output <promise>COMPLETE</promise> when all requirements are met and tests pass.
```

## 2. Incremental Goals

Break large tasks into phases within the prompt so Claude can make measurable progress each iteration.

**Weak** — too broad for a single loop:
```
Create a complete e-commerce platform.
```

**Strong** — phased with clear checkpoints:
```
Phase 1: User authentication (JWT, tests passing)
Phase 2: Product catalog (list/search endpoints, tests passing)
Phase 3: Shopping cart (add/remove, tests passing)

Complete phases in order. Output <promise>COMPLETE</promise> when all three phases have passing tests.
```

## 3. Self-Correction Instructions

Tell Claude explicitly to run verification and fix failures before advancing. This is what makes the loop useful for TDD.

**Weak** — no verification loop:
```
Write code for feature X.
```

**Strong** — explicit TDD cycle:
```
Implement feature X following TDD:
1. Write failing test (Red)
2. Implement minimal code to pass (Green)
3. Run tests — if any fail, debug and fix
4. Refactor while keeping tests green
5. Repeat until all tests pass

Output <promise>COMPLETE</promise> when all tests are green.
```

## 4. Escape Hatches

Always include `--max-iterations` as a safety net. For long-running loops, add a fallback instruction for when progress stalls.

```
Implement feature X using TDD.

If after 15 iterations the task is still incomplete:
- Document what is blocking progress
- List what was attempted and why it failed
- Suggest 2-3 alternative approaches

Output <promise>COMPLETE</promise> when all tests pass.
```

```bash
# For simple prompts (user input, short text):
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh" "Build a REST API" --completion-promise "COMPLETE" --max-iterations 20

# For complex prompts with special characters (task descriptions, code blocks, Gherkin scenarios):
# Write prompt to file first to avoid shell escaping issues
cat > ".claude/task-prompt.tmp.md" <<'PROMPT_EOF'
## Task: Complex task with special characters
...
PROMPT_EOF
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh" --prompt-file ".claude/task-prompt.tmp.md" --completion-promise "COMPLETE" --max-iterations 20
```

## Superpowers-Specific Patterns

### superpowers:brainstorming prompt structure

```
Brainstorm: <topic>

Work through phases: Discovery → Option Analysis → Design Creation → Design Reflection → Git Commit.
Output <promise>BRAINSTORMING_COMPLETE</promise> when all phases are complete and design is committed.
```

### superpowers:writing-plans prompt structure

```
Write an implementation plan for: <design-path>

Work through phases: Plan Structure → Task Decomposition → Validation → Plan Reflection → Git Commit.
Output <promise>PLAN_COMPLETE</promise> when plan is complete, reflected, and committed.
```

### superpowers:executing-plans prompt structure

```
Execute implementation plan: <plan-path>

Work through phases: Plan Review → Task Creation → Batch Execution → Verification → Git Commit.
Output <promise>EXECUTION_COMPLETE</promise> when all tasks are executed, verified, and committed.
```
