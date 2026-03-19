# Completion Promise Design

The completion promise is the exit condition for a Superpower Loop. The Stop hook scans the last assistant turn for `<promise>TEXT</promise>` and exits the loop when it finds an exact match.

## Mechanics

The Stop hook extracts the promise text using:

```bash
perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g; s/\s+/ /g'
```

Key implications:
- **Exact string match** — `"DONE"` and `"Done"` are different promises
- **Whitespace is normalized** — internal whitespace is collapsed to single spaces
- **Only one promise tag is matched** — the first `<promise>` tag wins
- **Multi-word promises need quotes** when passing via `--completion-promise` flag

## Designing a Good Promise

A completion promise should name a **state** that is objectively true or false, not a process.

**Weak** — describes an action, not a state:
```
"I have finished the implementation"
```

**Strong** — names a verifiable state:
```
"ALL_TESTS_PASSING"
"BRAINSTORMING_COMPLETE"
"PLAN_COMPLETE"
```

## Superpowers Promise Conventions

| Skill | Promise String | When It Is TRUE |
|-------|---------------|-----------------|
| `superpowers:brainstorming` | `BRAINSTORMING_COMPLETE` | All 4 phases done, design folder committed |
| `superpowers:writing-plans` | `PLAN_COMPLETE` | All phases done, plan folder committed |
| `superpowers:executing-plans` | `EXECUTION_COMPLETE` | All tasks executed, verified, and committed |

## Promise Integrity Rules

**MUST NOT** output a false promise — even when:
- Stuck and unable to make progress
- Believing the task is impossible
- Wanting to exit for any other reason

The loop is designed to continue until the promise is genuinely true. Use `--max-iterations` to set a limit, and include a fallback instruction in the prompt for when the limit is reached.

## Multiple Completion Conditions

The `--completion-promise` flag uses exact string matching. It cannot match multiple conditions (e.g., "SUCCESS" vs "BLOCKED").

**Pattern for tasks with multiple outcomes**: use a single promise that covers all exit paths, and encode the outcome in prose before the promise tag:

```
When done, report either:
  "All tests pass — task complete" or
  "Blocked after N attempts — see blocker notes"

Then output <promise>TASK_123_COMPLETE</promise> in either case.
```

The loop exits on the promise regardless; the prose before it carries the outcome.

## Safety Nets

Always pair `--completion-promise` with `--max-iterations`:

```bash
# Recommended: promise + iteration limit
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh" "..." \
  --completion-promise "DONE" \
  --max-iterations 20

# Without a promise: loop runs until max-iterations (or forever if 0)
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh" "..." \
  --max-iterations 10
```

If `max_iterations` is 0 and no completion promise is set, the loop runs infinitely. Never use this configuration in automated workflows.
