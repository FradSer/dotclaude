---
description: "Explain autoresearch plugin and available commands"
---

# Autoresearch Plugin Help

Explain the following to the user:

## What is autoresearch?

A Claude Code plugin inspired by [karpathy/autoresearch](https://github.com/karpathy/autoresearch) — an autonomous research loop where Claude acts as a researcher, continuously editing one artifact, running a scorer, logging results, and iterating overnight without human intervention.

Unlike the original (which is hardwired to ML training), this plugin is **domain-agnostic**: you supply the editable artifact, the scorer, and the optimization direction, so the loop works on any problem that reduces to *"edit something, run a command that prints one number, keep the change if the number improved."* ML training is just one configuration of it.

**Core idea:**
- Point Claude at one artifact it may edit and one scorer command that prints a number
- Let it experiment autonomously — make a change, score it, keep or discard, repeat
- Wake up in the morning to a log of experiments and (hopefully) a better score

**How the loop runs (this plugin's mechanism):**

Rather than an external shell loop, this plugin uses a Claude Code **Stop hook**. Every time Claude tries to end its turn, the hook intercepts the exit and re-injects the same research prompt — so Claude keeps experimenting in one continuous session. Claude sees its previous work in git history and `results.tsv`, building incrementally toward a better score. The hook stops the loop when a configured bound is hit (max experiments, wall-clock budget, or a completion promise).

This is the same spirit as the "ralph-loop" idea behind the original project (re-feeding a prompt until done), adapted to Claude Code's hook system instead of a `while` loop over a CLI.

## Requirements

- A git repository (the loop runs in a dedicated git **worktree** so your main checkout, current branch, and even a dirty tree are never touched)
- At least one bound: `--max-experiments` and/or `--max-wall-clock`
- An evaluator: a `--score-cmd` (prints a number as its **last** stdout line) and/or a `--check-cmd` (objective pass/fail gate, exit 0 = pass)
- Whatever runtime the evaluator needs (interpreter, data, GPU, ...) — that is its concern, not the plugin's

## Before a long run: raise the Stop-hook block cap

Claude Code force-ends the turn after a Stop hook blocks `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` times in a row (**default 8**). This loop re-blocks once per experiment, so any run that wants more than ~8 experiments will hit that ceiling and stop early unless you raise it.

Autoresearch already enforces its own bound (experiments / wall-clock / completion promise) inside the same Stop hook, so the generic cap is redundant here — disable it. Add to `.claude/settings.json` (or `~/.claude/settings.json`):

```json
{ "env": { "CLAUDE_CODE_STOP_HOOK_BLOCK_CAP": "0" } }
```

`"0"` disables the cap; or set a number comfortably above your experiment count. The env var is read at **session start**, so set it and restart Claude Code *before* the run — a plugin cannot set it for you, and it does not take effect mid-session. `/autoresearch:start` prints a reminder when your configured bound exceeds the active cap.

## Commands

### /autoresearch:start <goal> [overrides]

Give it a plain-language goal — `/autoresearch:start make X faster` — and it inspects the repo to infer the full contract, asking only when the artifact or evaluator is genuinely ambiguous. Pass any flag below to pin it as an override.

**Inferred (or overridden) contract:**
- `--edit <glob|path>` — the ONLY artifact the agent may modify
- An **evaluator** — at least one of:
  - `--score-cmd '<shell>'` — numeric scorer; LAST stdout line is a single number (needs `--direction`)
  - `--check-cmd '<shell>'` — objective gate; exit 0 = pass. Use alone to "iterate until it passes", or with `--score-cmd` as a hard filter on top of optimization.
  - `--rubric '<criteria>'` — criteria an LLM judge panel applies when a plateau escalates to a tournament. Must be anchored by `--score-cmd` or `--check-cmd` (a judge-only loop reward-hacks).
- `--direction min|max` — lower or higher score is better (only with `--score-cmd`)
- `--prompt` / `--objective` — the goal and its measurable restatement (auto-filled)

Plus at least one bound (`--max-experiments` or `--max-wall-clock`); the inference fills sensible defaults.

**Options:**
- `TAG` — branch suffix (e.g. `mar16`); defaults to today's date
- `--max-experiments <n>` — stop after N experiments
- `--max-wall-clock <duration>` — stop after a wall-clock budget (e.g. `8h`, `480m`, `30s`)
- `--readonly <path>` — protect a path from edits (repeatable)
- `--trial-timeout <duration>` — hard time limit per scorer run (default `600`s; plain numbers are seconds, unlike `--max-wall-clock`)
- `--precheck '<shell>'` — a precondition that must exit 0 before the loop starts (repeatable)
- `--completion-promise <text>` — Claude outputs `<promise>TEXT</promise>` to signal done
- `--force` — replace an existing active loop state file (use after `/autoresearch:cancel` if needed)
- `-h`, `--help` — show usage and exit

**Examples:**
```
# Data cleaning — maximize F1
/autoresearch:start clean1 --prompt 'improve the cleaning rules' \
  --objective 'maximize F1, precision >= 0.90' \
  --edit clean.py --readonly score.sh --score-cmd 'bash score.sh' \
  --direction max --max-experiments 20

# Prompt optimization — maximize eval accuracy
/autoresearch:start --prompt 'raise accuracy on the eval set' \
  --objective 'maximize accuracy' --edit prompt.txt \
  --score-cmd 'python eval_prompt.py --set val.jsonl' \
  --direction max --max-experiments 30

# ML training parity — reproduce the original behavior
/autoresearch:start --prompt 'lower validation bits-per-byte' \
  --objective 'minimize val_bpb' --edit train.py \
  --readonly prepare.py --readonly evaluate_bpb \
  --score-cmd 'timeout 600 uv run train.py >run.log 2>&1; grep "^val_bpb:" run.log | awk "{print \$2}"' \
  --direction min --max-wall-clock 8h
```

**What happens:**
1. Refuses to start unbounded, without an evaluator, or outside a git repo (a dirty main tree is fine — the run is isolated)
2. Runs any `--precheck` commands and aborts if one fails
3. Creates a dedicated git **worktree** (`.claude/worktrees/autoresearch-<tag>` on branch `autoresearch/<tag>`) — your checkout is never switched
4. Creates `.claude/autoresearch.local.md` state file (in the main repo) with the generated research prompt
5. The agent works inside the worktree: initializes `results.tsv` and scores a baseline first
6. Loops until the bound is reached: edit artifact → evaluate → log → keep (fold into a temporary WIP commit) / discard. The real commit is made by you afterward via `/git:commit`.

---

### /autoresearch:cancel

Force-stop an active research loop.

**Usage:**
```
/autoresearch:cancel
```

Run it from a **separate** session in the same project directory — the looping session is busy being re-prompted and can't run it itself. It removes `.claude/autoresearch.local.md`; the loop's next stop-hook fire then finds no state and exits cleanly.

---

### Hybrid loop: tournament on plateau

The loop runs cheap **sequential** rounds. When it plateaus (the last few rounds all non-improving — a local optimum), it escalates **one** round to a parallel **tournament** (the bundled GAN engine, `workflows/gan.mjs`), then resumes sequential:

1. Fan out a few candidate edits in parallel, each in an isolated git worktree, each self-evaluated.
2. A judge — or a 3-judge panel against your `--rubric` — ranks the survivors and flags graftable ideas from the runners-up.
3. A synthesis step combines the winner with those ideas and is **re-evaluated**; it only wins on a real re-measured result.
4. The winner is kept if it beats the current best; the loop returns to sequential rounds.

A tournament round costs ~100k+ tokens, so escalation is reserved for genuine plateaus, and only for a **single-file** `--edit` (the engine passes full file contents between agents). The `--rubric` evaluator lives here because independent judges can apply it without the self-judging reward-hack a single sequential agent would fall into.

---

## Experiment loop

Each experiment:
1. Make one concrete change to the `--edit` artifact (only that)
2. Evaluate: `timeout <trial-timeout> sh -c '<score-cmd>'` and/or the `--check-cmd` gate
3. Log to `results.tsv` (tab-separated: commit, score, status, description)
4. **Keep** if strictly better in `--direction` than `BEST_KEPT` and the gate passes — else **discard** (`git checkout -- <artifact>`)

**Commits are temporary.** The loop never makes a real commit: kept experiments fold into one rolling `autoresearch WIP (temporary)` scratch commit, and `results.tsv` is the durable log. After the run you review the result and land it through the dedicated flow — `git reset --soft <baseline>` then `/git:commit`. The real commit happens only after you confirm.

## Monitoring

```bash
# Current experiment number (main repo)
grep '^iteration:' .claude/autoresearch.local.md

# Experiment log (inside the worktree)
cat .claude/worktrees/autoresearch-<tag>/results.tsv
```

## Completion promise

To signal research is complete, Claude outputs:
```
<promise>RESEARCH COMPLETE</promise>
```

The stop hook detects this tag (when `--completion-promise` is configured) and ends the loop cleanly.

## Limitations

- **`iteration` counts re-prompts, not completed experiments.** The stop hook increments the counter every time it blocks an exit, whichever the reason. If a turn ends without finishing an experiment, the count still advances — so `--max-experiments N` is an upper bound on re-prompts, which usually but not always equals N completed experiments. Prefer `--max-wall-clock` when you care about total time rather than an exact experiment count.
- **The block-cap ceiling is external.** See "raise the Stop-hook block cap" above — the plugin warns but cannot set the env var itself.
- **`results.tsv` lives only in the working tree.** It is kept untracked on purpose (so discards preserve it). It is not committed, so it exists only on the experiment branch's working copy until you save it elsewhere.
