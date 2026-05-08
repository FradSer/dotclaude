# Bail-Out Reference

Detailed protocol for the bail-out check at the top of `../SKILL.md`. The full pipeline (per-batch coordinator + sprint contract + evaluator + handoff machinery) is calibrated for plans with 5+ tasks across 2+ batches. Smaller plans suffer net overhead.

## Bail-out trigger

Total task count from `_index.md` "Execution Plan" YAML is `< 5` AND would resolve to a single batch.

## Bail-out response (output verbatim, then proceed)

> Plan has < 5 tasks in a single batch; the per-batch coordinator + evaluator + handoff machinery is overhead. Executing tasks inline (read each task file, implement, verify) and committing once. To force the full pipeline, re-invoke as `/superpowers:executing-plans --force <plan-path>`.

## Inline execution mode (after bail-out)

1. Read each task file from the plan directory in dependency order (respect `depends-on` from YAML)
2. For each task:
   - Apply BDD Red-Green discipline if a test/impl pair exists
   - Run the verification command from the task file
   - Mark verification status inline in your response (no TaskUpdate ceremony)
3. After the last task, run a single git commit covering all changes (see `../../skills/references/git-commit.md`)
4. Output a one-line completion summary — no `<promise>` tag (no loop to exit)

Skip: sprint contract, handoff-state.md, sprint-contract-batch-N.md, evaluation-round-N-batch-M.md, harness-config read, plans-completed.jsonl append. None apply when the loop is not running.

## Override

`--force` as a literal token anywhere in `$ARGUMENTS` bypasses the check. Do not infer override from prose ("please force this") — only the literal token counts, to avoid accidental over-invocation.

## Calibration log

Always log the outcome — both bail-out and `--force` override — so retrospective Phase 5a can detect frequent override patterns:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/lib/bail-log.sh" executing-plans <event> "<short reason>" "$ARGUMENTS"
```

`<event>` is `bail_out` when running inline-execution mode, or `force_override` when `--force` bypassed the gate and the loop is being started. Run this once per invocation; it appends to `docs/retros/bail-out-events.jsonl` and never blocks.
