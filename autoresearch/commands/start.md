---
description: "Autonomously turn a plain-language goal into a research loop — infers the artifact, evaluator, and bounds, then iterates (sequential, escalating to a tournament when stuck)"
argument-hint: "<plain-language goal> [--edit PATH] [--score-cmd \"...\"] [--check-cmd \"...\"] [--rubric \"...\"] [--direction min|max] [--max-experiments N | --max-wall-clock 8h]"
allowed-tools: ["Read", "Glob", "Grep", "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-autoresearch.sh:*)", "Bash(git:*)", "AskUserQuestion"]
disable-model-invocation: true
---

# Autoresearch Start (autonomous)

Turn the user's free-text goal in `$ARGUMENTS` into a complete research contract by inspecting the repo, then launch the loop. Ask the user ONLY when something genuinely cannot be inferred. Any explicit flag the user passed in `$ARGUMENTS` (e.g. `--edit`, `--score-cmd`) is an OVERRIDE — use it verbatim and do not re-infer that field.

## Phase 1: Read the goal

The leading free text of `$ARGUMENTS` (before any `--flag`) is the GOAL. Record any override flags the user passed.

## Phase 2: Infer the contract from the repo

Inspect the repo (list files; read `package.json` / `Makefile` / `pyproject.toml` / `README`) and derive:

- **`--edit`** — the artifact to optimize. If the goal names a file or area, use it. Prefer a SINGLE file when the goal is about one thing — a single file unlocks the tournament escalation.
- **An evaluator** — prefer an OBJECTIVE one; a wrong evaluator wastes the whole run:
  1. The goal implies a measurable number and a command prints it → `--score-cmd '<cmd>'` + `--direction min|max`.
  2. Else the project has a test/check command (`package.json` `scripts.test`/`lint`/`typecheck`, a Makefile target, `pytest`, `cargo test`) and the goal is "make it work / keep it passing" → `--check-cmd '<cmd>'` (a pass/fail gate).
  3. Else the goal is qualitative (clarity, readability, prose, design) → `--rubric '<criteria distilled from the goal>'`, ANCHORED by a `--check-cmd` (a test/build that must keep passing). NEVER a rubric without a `--score-cmd` or `--check-cmd` anchor — a judge-only loop reward-hacks (the setup will refuse it).
  4. Combine when it fits (gate + score, or gate + rubric).
- **`--objective`** — a one-line measurable restatement of the goal (what success means).
- **Bounds** — default `--max-experiments 20`, unless the goal implies time ("overnight" → `--max-wall-clock 8h").
- **TAG** — a short slug from the goal (optional; defaults to the date).

## Phase 3: Ask only if truly ambiguous

If you cannot confidently pick the `--edit` artifact, or you found NO objective evaluator for a non-trivial goal, ask the user 1–2 focused questions with AskUserQuestion (e.g. "Which file should I optimize?", "What command measures success?"). Otherwise DO NOT ask — proceed.

## Phase 4: Launch

Run the setup script with the derived flags plus any overrides:

```
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-autoresearch.sh" [TAG] \
  --prompt "<the goal>" --objective "<derived objective>" \
  --edit <artifact> <evaluator flags> <bound flags> [--readonly <path>] \
  --session-id "${CLAUDE_SESSION_ID}"
```

Then report, in one line, the contract you chose (edit, evaluator, direction, bounds) so the user sees it. You are now the autonomous researcher: the stop hook re-injects the research prompt every turn until a bound is hit — do NOT pause for permission between experiments. The loop runs cheap sequential rounds and escalates one round to a parallel tournament when it plateaus (single-file artifacts). The human is asleep.
