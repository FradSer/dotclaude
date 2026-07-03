# Phase 3: Batch Execution Loop (main agent orchestration)

**CRITICAL — Context Reset Principle**: The main executing-plans agent does NOT execute batch tasks itself. Each batch runs inside a **fresh, isolated sub-agent context** spawned via the Agent tool (`subagent_type: "general-purpose"`). The main agent orchestrates only: plan metadata, TaskList, and `handoff-state.md` — it never accumulates batch execution transcripts.

**Main agent owns (kept across batches):** `_index.md`, TaskList, `handoff-state.md`, final Phase 5 commit.

**Each batch coordinator owns (discarded on return):** task files, verification, BDD execution, evaluator spawn, rework loops, implementation transcripts.

## Per-batch steps (main agent)

**ATOMIC**: Steps 0-2 in one response, Agent tool last. See `./batch-execution-playbook.md`.

0. **Sprint Contract** — Write `sprint-contract-batch-{N}.md` from `_index.md`, batch task files, BDD scenarios, latest `code-v{N}.md`. Acceptance criteria auto-derived from task Then-clauses (`./sprint-contract-template.md`). On scope change: archive to `sprint-contract-batch-{N}.v{M}.md`, never silent overwrite.

1. **Refresh Handoff State** — Rewrite `handoff-state.md` (completed IDs, cumulative modified files, recurring failure patterns). See `./handoff-template.md`.

2. **Spawn Batch Coordinator** — Agent tool, `subagent_type: "general-purpose"`. **HARD RULE**: no direct `Edit`/`Write` of source files on the main agent. Coordinator prompt MUST be self-contained and include:
   - Plan directory path; `sprint-contract-batch-{N}.md` path; `handoff-state.md` path
   - Resolved `docs/retros/checklists/code-v{N}.md` (highest N in repo when not passed explicitly)
   - Batch task IDs + Red-Green pair annotations; execution mode (see `./batch-execution-playbook.md`)
   - Full Agent Prompt Template + evaluator instruction + max 2 rework rounds + structured return format (below)
   - Both gate-skill directives: implementer prompts load `superpowers:verification-before-completion` before reporting done; the coordinator loads `superpowers:receiving-code-review` before acting on an evaluator REWORK (see playbook Agent Prompt Template + Rework Loop)

3. **Process Coordinator Result** — Parse structured return:
   ```
   Verdict: PASS | REWORK_ESCALATED | PIVOT
   Completed task IDs: [...]
   Evidence blocks: [...]
   Modified files: [...]
   Evaluation report path: evaluation-round-{N}-batch-{M}.md
   Recurring patterns detected: [...]
   Pivot recommendation: <text or null>
   ```
   - **PASS**: TaskUpdate tasks to `completed`
   - **PIVOT**: apply plan modifications, continue autonomously
   - **REWORK_ESCALATED**: HARD BLOCKER per `./blocker-and-escalation.md`; do NOT retry in main context

4. **Batch Completion** — Update `handoff-state.md`; proceed to Phase 4 handoff; next batch.

Coordinator internal patterns (Red-Green, Parallel, Linear, verification gate, rework, evaluator): `./batch-execution-playbook.md`.
