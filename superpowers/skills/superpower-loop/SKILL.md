---
name: superpower-loop
description: Starts, cancels, or explains the Superpower Loop iterative development methodology. Use when the user invokes `/superpower-loop`, asks to start a loop, cancel a loop, or needs to understand how iterative self-referential loops integrate with the superpowers workflow.
argument-hint: "[cancel | help | PROMPT [--max-iterations N] [--completion-promise TEXT]]"
user-invocable: true
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh:*)", "Bash(ls .claude/superpower-loop*.local.md:*)", "Bash(rm .claude/superpower-loop*.local.md:*)", "Read(.claude/superpower-loop*.local.md)"]
---

# Superpower Loop

Parse `$ARGUMENTS` and dispatch to one of three actions:

## Action: cancel

**Trigger**: `$ARGUMENTS` is exactly `cancel`

1. Find all active state files: `ls .claude/superpower-loop*.local.md 2>/dev/null || true`
2. **If none found**: Report "No active Superpower loop found."
3. **If one or more found**: For each file:
   - Read the file to get the iteration from the `iteration:` field
   - Remove the file: `rm <filepath>`
   - Report: "Cancelled Superpower loop <filepath> (was at iteration N)"

## Action: help

**Trigger**: `$ARGUMENTS` is empty or `help`

Explain the following to the user:

**What is Superpower Loop?**

Superpower Loop implements a Stop hook intercepts Claude's exit, feeds the same prompt back, and Claude iterates on its own previous work until a completion promise is output or the iteration limit is reached.

Each iteration: receive same prompt → work on task → try to exit → Stop hook intercepts → if no promise found, feeds prompt back → Claude sees previous work in files → repeat.

**Commands:**

`/superpowers:superpower-loop PROMPT [OPTIONS]` — Start a loop in the current session.

Options:
- `--max-iterations N` — Stop after N iterations (0 = unlimited)
- `--completion-promise TEXT` — Exact phrase that signals completion

`/superpowers:superpower-loop cancel` — Cancel the active loop (removes state file).

**How completion works:**

Output `<promise>YOUR_PHRASE</promise>` to exit the loop. The Stop hook matches the exact phrase against `--completion-promise`. Always set `--max-iterations` as a safety net.

**When to use:**
- Well-defined tasks with clear, verifiable success criteria
- TDD cycles (write failing test → implement → green → refactor → repeat)
- Multi-phase workflows (brainstorming, planning, execution)

**When NOT to use:**
- Tasks requiring human judgment at each step
- One-shot operations
- Ambiguous or subjective success criteria

**Superpowers integration:**

| Skill | Promise | Max Iterations |
|-------|---------|----------------|
| brainstorming | `BRAINSTORMING_COMPLETE` | 50 |
| writing-plans | `PLAN_COMPLETE` | 50 |
| executing-plans | `TASK_{taskId}_COMPLETE` | 20 per task |

See `./references/prompt-patterns.md` for prompt writing best practices.
See `./references/completion-promises.md` for completion promise design.

## Action: start loop

**Trigger**: `$ARGUMENTS` contains a prompt (anything other than `cancel` or `help`)

Execute the setup script:

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh" $ARGUMENTS
```

Work on the task. When you try to exit, the Stop hook feeds the SAME PROMPT back. Your previous work persists in files and git history — each iteration builds on the last.

CRITICAL: If a completion promise is set, only output `<promise>TEXT</promise>` when the statement is completely and unequivocally TRUE. Do not output a false promise to escape the loop. The promise tag MUST be the absolute last text output.

---

## Methodology Reference

Superpower Loop is self-referential through **file state, not prompt chaining**. Claude's previous work persists; each iteration builds incrementally on the last.

**Standard invocation pattern** used by all three superpowers skills:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh" "<prompt>" --completion-promise "<PROMISE>" --max-iterations <N>
```

Initialize the loop **immediately after capturing the initial prompt** — before beginning any phase work.

See `./references/prompt-patterns.md` for writing effective loop prompts.
See `./references/completion-promises.md` for completion promise design patterns.
