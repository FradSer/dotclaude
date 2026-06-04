# Autoresearch

An autonomous research loop inspired by [karpathy/autoresearch](https://github.com/karpathy/autoresearch). Claude acts as a researcher: it edits one artifact, runs a scorer, keeps the change if the score improved, logs the result, and iterates overnight without human intervention. Unlike the original — hardwired to ML training — this plugin is **domain-agnostic**: you supply the editable artifact, the scorer, and the optimization direction, so it works on any problem that reduces to *"edit something, run a command that prints one number, keep the change if the number improved."*

## How the loop runs

Rather than an external shell `while` loop, the plugin uses a Claude Code **Stop hook**. Every time Claude tries to end its turn, the hook intercepts the exit and re-injects the same research prompt — so Claude keeps experimenting in one continuous session, building on its previous work (visible in git history and `results.tsv`). The hook stops the loop when a configured bound is reached: max experiments, wall-clock budget, or a completion promise. Same spirit as the "ralph-loop", adapted to Claude Code's hook system.

## Installation

```bash
claude plugin install autoresearch@frad-dotclaude
```

## Commands

| Command | What it does |
|---------|--------------|
| `/autoresearch:start [TAG] <contract> [options]` | Start the loop in the current session on a dedicated `autoresearch/<tag>` branch. |
| `/autoresearch:cancel` | Force-stop an active loop. Run from a **separate** session — the looping session is busy being re-prompted. |
| `/autoresearch:help` | Explain the plugin and its commands. |

## Requirements

- **A git repository.** The loop runs on a dedicated `autoresearch/<tag>` branch so its auto-discards (`git reset --hard`) never touch your work. It refuses to start on a dirty tree.
- **At least one bound:** `--max-experiments` and/or `--max-wall-clock`. It refuses to start unbounded.
- **A `--score-cmd`** that prints one comparable number as its **last** stdout line.
- **`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`** raised for runs longer than ~8 experiments — see below.
- Whatever runtime the scorer needs (interpreter, data, GPU, ...) — that is your scorer's concern, not the plugin's.

## Before a long run: raise the Stop-hook block cap

Claude Code force-ends the turn after a Stop hook blocks `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` times in a row (**default 8**). This loop re-blocks once per experiment, so any run that wants more than ~8 experiments hits that ceiling and stops early unless you raise it.

Autoresearch enforces its own bound (experiments / wall-clock / completion promise) inside the same Stop hook, so the generic cap is redundant here — disable it. Add to `.claude/settings.json` (or `~/.claude/settings.json`):

```json
{ "env": { "CLAUDE_CODE_STOP_HOOK_BLOCK_CAP": "0" } }
```

`"0"` disables the cap; or set a number comfortably above your experiment count. The variable is read at **session start**, so set it and restart Claude Code *before* the run — a plugin cannot set it for you, and it does not take effect mid-session. `/autoresearch:start` prints a reminder whenever your configured bound exceeds the active cap.

## The contract

| Flag | Meaning |
|------|---------|
| `--prompt '<text>'` | Free-form research goal handed to the agent. |
| `--objective '<text>'` | The measurable target being optimized. |
| `--edit <glob\|path>` | The ONLY artifact the agent may modify. |
| `--score-cmd '<shell>'` | Command whose LAST stdout line is a single number. |
| `--direction min\|max` | Whether a lower or higher score is better. |

Plus at least one of `--max-experiments <n>` / `--max-wall-clock <duration>`.

Options: `--readonly <path>` (protect a path, repeatable), `--trial-timeout <duration>` (per-scorer-run hard limit, default `600`s; plain numbers are seconds), `--precheck '<shell>'` (precondition that must exit 0, repeatable), `--completion-promise '<text>'` (agent outputs `<promise>TEXT</promise>` to signal done), `--force` (replace an existing active state file).

## Experiment loop

Each experiment:

1. Choose one concrete change aimed at the objective.
2. Modify the `--edit` artifact (only that) and `git add <artifact>` — never `git add -A`.
3. `git commit`.
4. `timeout <trial-timeout> sh -c '<score-cmd>'`; read the **last** stdout line as the score.
5. Log to `results.tsv` (tab-separated: commit, score, status, description). Crashes are logged with score `NA` and always discarded.
6. Keep the commit only if the score is strictly better, in `--direction`, than the best `keep` score so far (`BEST_KEPT`). Otherwise `git reset --hard HEAD~1`.

`results.tsv` is kept **untracked** so a discard preserves the log; the plugin instructs the agent never to stage it.

## Examples

```
# Prompt optimization — maximize eval accuracy
/autoresearch:start --prompt 'raise accuracy on the eval set' \
  --objective 'maximize accuracy' --edit prompt.txt \
  --score-cmd 'python eval_prompt.py --set val.jsonl' \
  --direction max --max-experiments 30

# ML training parity — minimize validation bits-per-byte
/autoresearch:start --prompt 'lower validation bits-per-byte' \
  --objective 'minimize val_bpb' --edit train.py \
  --readonly prepare.py --readonly evaluate_bpb \
  --score-cmd 'timeout 600 uv run train.py >run.log 2>&1; grep "^val_bpb:" run.log | awk "{print \$2}"' \
  --direction min --max-wall-clock 8h
```

More worked examples live in [`examples/`](examples/): data cleaning, prompt optimization, ML training, and solver tuning.

## Monitoring

```bash
grep '^iteration:' .claude/autoresearch.local.md   # current experiment number
cat results.tsv                                     # experiment log
```

## Limitations

- **`iteration` counts re-prompts, not completed experiments** — if a turn ends without finishing an experiment, the count still advances. Prefer `--max-wall-clock` when you care about total time rather than an exact experiment count.
- **The block-cap ceiling is external** — the plugin warns but cannot set `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` itself.
- **`results.tsv` lives only in the working tree** — kept untracked on purpose; save it elsewhere if you need it after deleting the branch.
