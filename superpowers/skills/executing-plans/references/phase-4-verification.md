# Phase 4: Verification & Feedback (executing-plans)

Runs in the main agent context. Evidence comes from the coordinator's structured return — do NOT re-run verification in the main context.

1. **Publish Evidence** — Per completed task, output a compact block (command, last 20 lines, PASS) from the coordinator payload.

2. **Pattern Scan** — Read evaluation reports; items FAIL in 2+ batches → inject into next sprint contract preamble (`./intra-plan-learning.md`).

3. **Persistent Patterns** — Item FAIL in 3+ batches → `PERSISTENT PATTERN` warning in handoff; continue autonomously.

4. **Batch Handoff** — Lightweight context block + update `handoff-state.md`.

5. **Handoff Summary** — Write `handoff-summary-{N}.md` every batch (`./handoff-template.md`).

6. **Proceed** — No user confirmation between batches.

7. **Loop** — Repeat Phase 3–4 until done. Under `/goal`, Step 1 `batch-progress.sh` resumes the correct batch.

8. **Checklist Evolution Candidates** — On plan completion, emit candidates per `./intra-plan-learning.md`.
