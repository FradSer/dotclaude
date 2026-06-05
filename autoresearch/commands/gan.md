---
description: "GAN-style tournament optimizer: fan out candidate edits, judge, synthesize the best, re-score, iterate to a target score"
argument-hint: "[TAG] --prompt \"...\" --objective \"...\" --edit FILE (--score-cmd \"...\" --direction min|max | --check-cmd \"...\" | --rubric \"...\") --max-rounds N [--target-score X] [--candidates N] [--readonly PATH]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/gan-setup.sh:*)", "Bash(git:*)", "Workflow", "Write", "Read"]
disable-model-invocation: true
---

# Autoresearch GAN

A tournament optimizer for a single-file artifact, complementary to the overnight
ralph-loop (`/autoresearch:start`). Each round fans out N candidate edits in
isolated worktrees, evaluates each with the configured evaluator (numeric
`--score-cmd`, objective gate `--check-cmd`, and/or an anchored LLM `--rubric`),
lets a judge (or a 3-judge rubric panel) rank them and flag graftable ideas from
the runners-up, synthesizes the winner with those ideas, re-evaluates, and keeps
the best — looping until `--target-score` / `--max-rounds` / two dry rounds. The
objective signal is always the arbiter; synthesis only wins on a real re-measure.

This runs a multi-agent **Workflow** (many parallel agents — expect real token
cost). You opted into that orchestration by invoking this command.

## Phase 1: Validate and isolate

Run the setup script with the user's arguments:

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/gan-setup.sh" $ARGUMENTS
```

- The script validates the contract, enforces the single-file `--edit`, checks for
  a clean tree, and switches to a dedicated `autoresearch/gan-<tag>` branch.
- On success its **last stdout line is a one-line JSON config**. Capture that JSON.
- If it exits non-zero (missing flags, multi-file edit, dirty tree, not a git
  repo), surface the stderr message to the user and STOP — do not run the workflow.

## Phase 2: Run the GAN workflow

Call the **Workflow** tool with the bundled script, passing the captured JSON as
`args` (an actual JSON value, not a string):

- `scriptPath`: `${CLAUDE_PLUGIN_ROOT}/workflows/gan.mjs`
- `args`: the JSON object printed by the setup script

The workflow returns an object:
`{ mode, best_score, best_content, best_description, best_gate_pass, baseline_score, target_score, target_reached, rounds, stop_reason, history }`.
`best_score` is null in `rubric`/`gate` modes (no numeric scale) — use `mode`,
`best_description`, and `best_gate_pass` to describe the outcome there.

## Phase 3: Persist and report

1. If the workflow returned `error`, report it and stop (the branch is left as-is).
2. Write a log of the tournament to `gan-results.tsv` (tab-separated `round`,
   `kind`, `score` from `history`) for the user to inspect. Leave it untracked.
3. If `best_content` differs from the current file AND the run made progress
   (numeric mode: `best_score` improved over `baseline_score` in `--direction`;
   rubric mode: a round reported an improvement; gate mode: `best_gate_pass` is
   true and the baseline did not pass):
   - Write `best_content` to the `--edit` file (the `edit` field of the config).
   - Commit on the gan branch: `git add <edit-file> && git commit -m "gan(<mode>): <best_description>"`.
   Otherwise report that nothing beat the baseline and make no commit.
4. Report to the user: the `mode`, baseline -> best outcome (score for numeric;
   "gate now passes" / "judged best of N" otherwise), whether the target was
   reached, the number of rounds, the `stop_reason`, the branch name, and a one-
   line summary of the winning change. Mention they can merge the gan branch or
   discard it.
