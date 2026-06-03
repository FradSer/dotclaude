---
description: "Explain autoresearch plugin and available commands"
---

# Autoresearch Plugin Help

Explain the following to the user:

## What is autoresearch?

A Claude Code plugin that replicates [karpathy/autoresearch](https://github.com/karpathy/autoresearch) — an autonomous ML research loop where Claude acts as a researcher, continuously modifying `train.py`, running 5-minute training experiments, logging results, and iterating overnight without human intervention.

**Core idea:**
- Give Claude a small but real LLM training setup
- Let it experiment autonomously — modify code, train 5 min, check if result improved, keep or discard, repeat
- Wake up in the morning to a log of experiments and (hopefully) a better model

**How the loop runs (this plugin's mechanism):**

Rather than an external shell loop, this plugin uses a Claude Code **Stop hook**. Every time Claude tries to end its turn, the hook intercepts the exit and re-injects the same research prompt — so Claude keeps experimenting in one continuous session. Claude sees its previous work in git history and `results.tsv`, building incrementally toward a lower `val_bpb`. The hook stops the loop when a configured bound is hit (max experiments, wall-clock budget, or a completion promise).

This is the same spirit as the "ralph-loop" idea behind the original project (re-feeding a prompt until done), adapted to Claude Code's hook system instead of a `while` loop over a CLI.

## Requirements

- Single NVIDIA GPU (tested on H100)
- Python 3.10+ with [uv](https://docs.astral.sh/uv/)
- A git repository with `train.py` and `prepare.py` in the working directory
- Data prepared once: `uv run prepare.py` (writes shards + tokenizer to `~/.cache/autoresearch/`)

## Commands

### /autoresearch:start [TAG] [OPTIONS]

Start the autonomous research loop in your current session.

**Usage:**
```
/autoresearch:start --max-wall-clock 8h
/autoresearch:start mar16 --max-experiments 50
/autoresearch:start --completion-promise 'RESEARCH COMPLETE' --max-experiments 100
```

**Options:**
- `TAG` — branch suffix (e.g. `mar16`); defaults to today's date
- `--max-experiments <n>` — stop after N experiments
- `--max-wall-clock <duration>` — stop after a wall-clock budget (e.g. `8h`, `480m`, `30s`)
- `--completion-promise <text>` — Claude outputs `<promise>TEXT</promise>` to signal done
- `-h`, `--help` — show usage and exit

At least one of `--max-experiments` or `--max-wall-clock` is **required** — the loop refuses to start unbounded.

**What happens:**
1. Refuses to start unbounded, on a dirty tree, or outside a git repo
2. Deterministically checks out or creates branch `autoresearch/<tag>` (so auto-discards never touch your current branch)
3. Creates `.claude/autoresearch.local.md` state file with research instructions
4. Initializes `results.tsv` if missing
5. Runs baseline experiment first
6. Loops until the bound is reached: modify train.py → commit → run → log → keep/discard

---

### /autoresearch:cancel

Force-stop an active research loop.

**Usage:**
```
/autoresearch:cancel
```

Run it from a **separate** session in the same project directory — the looping session is busy being re-prompted and can't run it itself. It removes `.claude/autoresearch.local.md`; the loop's next stop-hook fire then finds no state and exits cleanly.

---

## Experiment loop

Each experiment:
1. Choose an idea (architecture, optimizer, hyperparams, batch size...)
2. Modify `train.py`
3. `git commit`
4. `uv run train.py > run.log 2>&1` (always 5 min fixed budget)
5. Read `val_bpb` metric — lower is better
6. Log to `results.tsv` (tab-separated: commit, val_bpb, memory_gb, status, description)
7. If improved: keep commit. Else: `git reset --hard HEAD~1`

## Monitoring

```bash
# Current experiment number
grep '^iteration:' .claude/autoresearch.local.md

# Experiment log
cat results.tsv

# Latest run output
tail -20 run.log
```

## Completion promise

To signal research is complete, Claude outputs:
```
<promise>RESEARCH COMPLETE</promise>
```

The stop hook detects this tag and ends the loop cleanly.
