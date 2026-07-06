# Large-scale parallel batches via the native `Workflow` tool

Shared reference for the parallel-execution escalation path in `executing-plans`. The default per-batch fan-out (Agent tool, bounded spawn rounds) stays as-is for small batches; this file covers when and how to delegate a **large** independent-task batch to Claude Code's built-in `Workflow` tool instead of hand-rolling worker scheduling.

## What `Workflow` is

Claude Code's built-in multi-agent orchestration runtime. A JS script (`agent()`, `parallel()`, `pipeline()`) fans work out across sub-agents the platform schedules for you:

- **Concurrency is automatic** — capped at `min(16, cores-2)`; excess `agent()` calls queue and drain as slots free. This replaces the playbook's hand-rolled "4 per spawn round → wait → next 4" loop.
- **Out-of-context by construction** — the workflow runs in the background and keeps every sub-agent transcript out of the main agent's context. Same context-reset goal the coordinator already enforces, but for the whole batch at once.
- **Structured returns** — pass a JSON Schema and `agent()` returns a validated object, no parsing.
- A single `parallel()`/`pipeline()` call accepts up to 4096 items; lifetime cap is 1000 agents.

## Rule 1 — user must opt in (platform requirement)

`Workflow` may be called **only when the user has explicitly opted into multi-agent orchestration**. A skill running silently under `/goal` must NOT quietly fan out dozens of background agents — that burns tokens at a scale the user did not ask for. Treat opt-in as present when any of these hold:

- the user said "use a workflow" / "fan out agents" / "orchestrate with subagents" (their own words), OR
- ultracode is on for the session (a system-reminder confirms it), OR
- the user's request itself asks for large-scale parallelism on this run.

If none hold, **do NOT escalate** — run the default bounded spawn-round path in `batch-execution-playbook.md` Parallel Mode. Surface the option in one line ("this batch has N independent tasks; reply 'use a workflow' to fan them out in the background") and move on. This mirrors the `/goal` constraint (see `./goal-wrapper.md`): the platform feature is recommended in docs, never silently self-enabled.

## Rule 2 — when escalation is worth it

Escalate to `Workflow` only when **both**:

1. the batch has **many independent tasks** — roughly >4, i.e. exactly the case where the default path would otherwise serialize into multiple 4-wide spawn rounds, AND
2. the tasks are genuinely parallel (no Red-Green pairing, no cross-task file dependencies that would need worktree isolation per item — though `isolation: 'worktree'` is available per-`agent()` when they do).

For ≤4 independent tasks, or any Red-Green / Linear batch, the default Agent-tool path is simpler and cheaper — do not reach for `Workflow`.

## How to delegate the batch

The coordinator owns the contract; the workflow owns scheduling. Map one task → one `agent()` call inside a single `parallel()` (or `pipeline()` when each task is implement-then-verify). Keep the existing per-task discipline inside each agent prompt:

- carry the full Agent Prompt Template (Task Assignment + Quality Requirements + Verification) verbatim into each `agent()` prompt, and
- run the verification gate as a second `pipeline()` stage (or inside the same agent) so a task only counts done after its verification command exits 0.

The evaluator stays a **separate** step after the workflow returns — spawn `superpowers-evaluator` as usual on the merged produced-files set. Do not fuse evaluation into the implementation agents (same independence rule as Parallel Mode step 5).

After the workflow returns, the coordinator processes its structured results exactly like a normal batch: collect modified files, run/confirm verification evidence, `TaskUpdate` to `completed` only after the evaluator verdict is PASS.
