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

- A git repository (the loop runs on a dedicated `autoresearch/<tag>` branch so auto-discards never touch your work)
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

### /autoresearch:start [TAG] [CONTRACT] [OPTIONS]

Start the autonomous research loop in your current session.

**The required contract:**
- `--prompt '<text>'` — the free-form research goal handed to the agent
- `--objective '<text>'` — the measurable target you are optimizing
- `--edit <glob|path>` — the ONLY artifact the agent may modify
- An **evaluator** — at least one of:
  - `--score-cmd '<shell>'` — numeric scorer; LAST stdout line is a single number (needs `--direction`)
  - `--check-cmd '<shell>'` — objective gate; exit 0 = pass. Use alone to "iterate until it passes", or with `--score-cmd` as a hard filter on top of optimization.
- `--direction min|max` — lower or higher score is better (only with `--score-cmd`)

(LLM-rubric evaluation lives in `/autoresearch:gan`, which has independent judges.)

Plus at least one bound (`--max-experiments` or `--max-wall-clock`).

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
1. Refuses to start unbounded, without the contract flags, on a dirty tree, or outside a git repo
2. Runs any `--precheck` commands and aborts if one fails
3. Deterministically checks out or creates branch `autoresearch/<tag>` (so auto-discards never touch your current branch)
4. Creates `.claude/autoresearch.local.md` state file with the generated research prompt
5. The agent initializes `results.tsv` and scores a baseline first
6. Loops until the bound is reached: edit artifact → commit → run scorer → log → keep/discard

---

### /autoresearch:cancel

Force-stop an active research loop.

**Usage:**
```
/autoresearch:cancel
```

Run it from a **separate** session in the same project directory — the looping session is busy being re-prompted and can't run it itself. It removes `.claude/autoresearch.local.md`; the loop's next stop-hook fire then finds no state and exits cleanly.

---

### /autoresearch:gan [TAG] [CONTRACT] --max-rounds N [--target-score X]

A foreground, multi-agent **tournament** optimizer for a single-file artifact — complementary to the overnight `/autoresearch:start`. Each round:

1. Fan out `--candidates` candidate edits in parallel, each in an isolated git worktree, each self-evaluated.
2. A judge (or a 3-judge rubric panel) ranks them and flags graftable ideas from the runners-up.
3. A synthesis step combines the winner with those ideas and is re-evaluated.
4. Keep the best; loop until `--target-score` / `--max-rounds` / two dry rounds.

GAN takes the same pluggable evaluator as `start` **plus an LLM rubric**:
- `--score-cmd` + `--direction` — numeric; ranks directly.
- `--check-cmd` — objective gate; filters out failing candidates (also "find a passing variant" on its own).
- `--rubric '<criteria>'` — an adversarial judge panel ranks candidates against your criteria. To resist reward-hacking it **must be anchored** by `--score-cmd` or `--check-cmd`; the carried-over best competes each round so quality only ratchets up.

It runs a Claude Code **Workflow** (many parallel agents — real token cost) on a dedicated `autoresearch/gan-<tag>` branch and commits the winning artifact there. The objective signal is always the arbiter; synthesis only wins on a real re-measured result.

**GAN vs the ralph-loop:** `start` is sequential, overnight, single-session hill-climbing over any `--edit` target; `gan` is parallel, foreground, single-file, tournament + synthesis toward a `--target-score`. GAN has no `--max-wall-clock` (a Workflow script cannot read the clock) — bound it with `--max-rounds`.

```
# raise prompt accuracy via a 6-round tournament, stop early at 0.95
/autoresearch:gan --prompt 'raise accuracy on the eval set' \
  --objective 'maximize accuracy on val.jsonl' --edit prompt.txt \
  --score-cmd 'python eval_prompt.py --set val.jsonl' \
  --direction max --max-rounds 6 --target-score 0.95 --candidates 4
```

---

## Experiment loop

Each experiment:
1. Choose one concrete change aimed at the objective
2. Modify the `--edit` artifact (only that)
3. `git commit`
4. `timeout <trial-timeout> sh -c '<score-cmd>'`
5. Read the scorer's **last** stdout line as the score
6. Log to `results.tsv` (tab-separated: commit, score, status, description)
7. If the score improved in `--direction`: keep the commit. Else: `git reset --hard HEAD~1`

## Monitoring

```bash
# Current experiment number
grep '^iteration:' .claude/autoresearch.local.md

# Experiment log
cat results.tsv
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
