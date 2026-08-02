---
description: "Turn a plain-language goal into a research contract by inspecting the repo, grill the contract with the user one decision at a time (goal measurability, artifact, evaluator, bounds), then launch the loop (sequential, escalating to a tournament when stuck)"
argument-hint: "<plain-language goal> [--edit PATH] [--score-cmd \"...\"] [--check-cmd \"...\"] [--rubric \"...\"] [--direction min|max] [--max-experiments N | --max-wall-clock 8h]"
allowed-tools: ["Read", "Glob", "Grep", "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-autoresearch.sh:*)", "Bash(git:*)", "AskUserQuestion"]
disable-model-invocation: true
---

# Autoresearch Start (autonomous)

Turn the user's free-text goal in `$ARGUMENTS` into a complete research contract by inspecting the repo, then **grill the contract with the user** (one decision at a time, each with a recommended answer) before launching the loop. A wrong contract — especially a wrong evaluator — wastes the whole overnight run, so the contract is a shared decision, not an inference. Any explicit flag the user passed in `$ARGUMENTS` (e.g. `--edit`, `--score-cmd`) is an OVERRIDE — the user already decided that field; use it verbatim and do not re-infer or re-grill it.

## Phase 1: Read the goal

The leading free text of `$ARGUMENTS` (before any `--flag`) is the GOAL. Record any override flags the user passed.

**Empty goal is a refusal.** If `$ARGUMENTS` is empty or whitespace-only, STOP and ask the user for the goal — a loop with no goal has no contract, and every later decision hangs off it.

## Phase 2: Infer the contract from the repo

Inspect the repo (list files; read `package.json` / `Makefile` / `pyproject.toml` / `README`) and derive **recommendations** for every field (the grill in Phase 3 turns each into a decision):

- **`--edit`** — the artifact to optimize. If the goal names a file or area, use it. Prefer a SINGLE file when the goal is about one thing — a single file unlocks the tournament escalation.
- **An evaluator** — prefer an OBJECTIVE one; a wrong evaluator wastes the whole run:
  1. The goal implies a measurable number and a command prints it → `--score-cmd '<cmd>'` + `--direction min|max`.
  2. Else the project has a test/check command (`package.json` `scripts.test`/`lint`/`typecheck`, a Makefile target, `pytest`, `cargo test`) and the goal is "make it work / keep it passing" → `--check-cmd '<cmd>'` (a pass/fail gate).
  3. Else the goal is qualitative (clarity, readability, prose, design) → `--rubric '<criteria distilled from the goal>'`, ANCHORED by a `--check-cmd` (a test/build that must keep passing). NEVER a rubric without a `--score-cmd` or `--check-cmd` anchor — a judge-only loop reward-hacks (the setup will refuse it).
  4. Combine when it fits (gate + score, or gate + rubric).
- **`--objective`** — a one-line measurable restatement of the goal (what success means).
- **Bounds** — default `--max-experiments 20`, unless the goal implies time ("overnight" → `--max-wall-clock 8h").
- **TAG** — a short slug from the goal (optional; defaults to the date). No need to ask — it is internal.

## Phase 3: Grill the contract (one decision at a time)

Phase 2's inferences are **recommendations, not decisions**. The contract decides an overnight run — grill each decision with the user before launching. Method (from the superdev grilling skill):

- **One question at a time.** Ask via AskUserQuestion, wait for the answer, then continue. Multiple questions at once is bewildering.
- **Each question leads with your recommended answer** (first option, marked Recommended) — the user confirms, edits, or defers to your choice.
- **Facts come from the environment, decisions from the user.** Look up anything checkable in the repo yourself (does the command exist? what does it print?); never ask what you can verify.
- **Do not launch until every decision below is confirmed** — a shared understanding is the contract.

Question tree — resolve in this order (each decision may change the next):

1. **Goal measurability** (the trust root). Restate the goal as `--objective` and name the evaluator family that fits. Ask: "Success means: <objective>. Does this measure your goal?" — if the user cannot point to a number or a pass/fail gate, do NOT silently default to a rubric: surface the risk explicitly (a judge-only loop reward-hacks) and recommend an objective anchor, or ask what a pass would look like to them.
2. **Artifact** (`--edit`). Recommend the single file. Ask only if the goal named no file/area.
3. **Evaluator.** Present the recommended `--score-cmd` / `--check-cmd`; confirm the command exists and prints what the contract expects (verify in the repo first — do not ask what you can check). For qualitative goals, confirm the gate anchor.
4. **Bounds.** Recommend `--max-experiments 20` or `--max-wall-clock 8h`; the time/token cost is the user's call.

If the user answers "you decide" / skips a question, proceed with your recommendation — the question was still surfaced, the risk was stated, and the decision is recorded.

## Phase 4: Launch

Run the setup script with the confirmed flags plus any overrides:

```
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-autoresearch.sh" [TAG] \
  --prompt "<the goal>" --objective "<derived objective>" \
  --edit <artifact> <evaluator flags> <bound flags> [--readonly <path>] \
  --session-id "${CLAUDE_SESSION_ID}"
```

The setup prints the path of an isolated git **worktree** (`.claude/worktrees/autoresearch-<tag>`) — the run happens there, so the user's checkout and branch are never touched. `cd` into it, then report in one line the contract you chose (edit, evaluator, direction, bounds). You are now the autonomous researcher: the stop hook re-injects the research prompt every turn until a bound is hit — do NOT pause for permission between experiments. The loop runs cheap sequential rounds and escalates one round to a parallel tournament when it plateaus (single-file artifacts). Experiments fold into a temporary WIP commit; the human lands the result via `/git:commit` afterward. The human is asleep.
