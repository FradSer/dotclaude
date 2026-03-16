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

**Powered by the ralph-loop technique:**
```
while :; do
  <research prompt> | claude-code --continue
done
```

The Stop hook intercepts every exit attempt and feeds the same research prompt back. Claude sees its previous work in git history and `results.tsv`, building incrementally toward a lower `val_bpb`.

## Requirements

- Single NVIDIA GPU (tested on H100)
- Python 3.10+ with [uv](https://docs.astral.sh/uv/)
- An autoresearch-compatible project with `train.py` and `prepare.py`
- Data prepared once: `uv run prepare.py`

## Commands

### /autoresearch:start [TAG] [OPTIONS]

Start the autonomous research loop in your current session.

**Usage:**
```
/autoresearch:start
/autoresearch:start mar16 --max-experiments 50
/autoresearch:start --completion-promise 'RESEARCH COMPLETE' --max-experiments 100
```

**Options:**
- `TAG` — branch suffix (e.g. `mar16`); defaults to today's date
- `--max-experiments <n>` — stop after N experiments (default: unlimited)
- `--completion-promise <text>` — Claude outputs `<promise>TEXT</promise>` to signal done

**What happens:**
1. Creates `.claude/autoresearch.local.md` state file with research instructions
2. Checks out or creates branch `autoresearch/<tag>`
3. Initializes `results.tsv` if missing
4. Runs baseline experiment first
5. Loops forever: modify train.py → commit → run → log → keep/discard

---

### /autoresearch:cancel

Force-stop an active research loop.

**Usage:**
```
/autoresearch:cancel
```

Removes `.claude/autoresearch.local.md`. The stop hook will no longer intercept exits.

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
