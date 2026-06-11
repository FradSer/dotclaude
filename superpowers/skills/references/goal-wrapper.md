# Running superpowers skills under `/goal`

Shared reference for the `## Recommended: run wrapped in /goal` section of every user-invocable superpowers skill. The SKILL.md sections carry the per-skill example command and the two load-bearing rules; this file carries the full semantics.

## What `/goal` is

Claude Code's built-in autonomous-continuation wrapper (v2.1.139+, [upstream docs](https://code.claude.com/docs/en/goal)): "keep working until condition X holds". It provides the multi-turn continuation that the plugin's v2.x bash runtime used to provide (removed in v3.0.0) — from the platform rather than from hand-rolled hooks.

## Rule 1 — user-typed outer wrapper

`/goal` must prefix the invocation, typed by the user:

```
/goal "<completion condition>" /superpowers:<skill> <args>
```

A skill cannot enable `/goal` for itself mid-run. Skills may only *recommend* it in their docs (as each SKILL.md does); if a run was started without it, the run is single-turn-driven and resumes from filesystem state on the next manual turn.

## Rule 2 — conditions must be transcript-verifiable

After each turn, a fresh fast model checks the condition against the conversation transcript and re-prompts until satisfied. **The evaluator does NOT read files or run commands.** Phrase the condition as something Claude's own narration will demonstrate:

| Verifiable (narrated in transcript) | Unverifiable (filesystem state — will time out) |
|---|---|
| commit-hash narration from `git-agent commit` | `_index.md exists` / `status=completed` |
| the literal evaluator verdict line ("verdict is PASS") | `evaluator PASS report` file present |
| an explicit "Phase N complete" statement | `git commit clean` / `checklists/ updated` |
| a printed test-run result | "the regression test file exists" |

## Recommended conditions per skill

| Skill | Condition |
|---|---|
| brainstorming | "Claude has narrated a successful design commit (with commit hash) and the evaluator's verdict is PASS" |
| writing-plans | "Claude has narrated a successful plan commit (with commit hash) and reported the Phase 4 reflection sub-agent verdicts inline" |
| executing-plans | "Claude has emitted the Phase 6 completion message 'Plan execution complete. All N tasks verified and committed' AND has reported the final commit hash from Phase 5 in the transcript" |
| systematic-debugging | "Claude has narrated the three-part completion output (root-cause one-liner, fix diff summary, regression-test path) with the regression test passing" |
| retrospective | "Claude has narrated a successful checklist-evolution commit (with commit hash) and stated the retrospective is complete" |

**executing-plans caveat**: it commits **once** at Phase 5 after all batches finish, not once per batch — do not phrase the condition around a per-batch commit hash or it will never match. Per-batch evaluator verdicts ARE narrated inline during Phase 4 of each batch, but those are progress signals, not completion signals.

## Interaction with bail-out checks

Each skill's `## CRITICAL: Bail-Out Check` still short-circuits trivial inputs — `/goal` then simply confirms completion on the first turn. Wrapping in `/goal` never forces the full pipeline onto trivial work.

## Mid-stream control

On a `/goal` re-prompt turn the user can inject corrections ("abort", "cancel", "actually this is about X") — see the per-skill mid-stream sections (brainstorming pivots, writing-plans cancellation/resumption) for how each skill handles them.
