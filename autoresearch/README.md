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
| `/autoresearch:start [TAG] <contract> [options]` | Start the overnight ralph-loop in the current session on a dedicated `autoresearch/<tag>` branch. |
| `/autoresearch:gan [TAG] <contract> --max-rounds N [--target-score X]` | Run a foreground GAN-style tournament (parallel candidates → judge → synthesize → re-score) over a single-file artifact, iterating to a target score. |
| `/autoresearch:cancel` | Force-stop an active loop. Run from a **separate** session — the looping session is busy being re-prompted. |
| `/autoresearch:help` | Explain the plugin and its commands. |

## Requirements

- **A git repository.** The loop runs on a dedicated `autoresearch/<tag>` branch so its auto-discards (`git reset --hard`) never touch your work. It refuses to start on a dirty tree.
- **At least one bound:** `--max-experiments` and/or `--max-wall-clock`. It refuses to start unbounded.
- **An evaluator:** a `--score-cmd` (prints a number as its **last** stdout line) and/or a `--check-cmd` (pass/fail gate, exit 0 = pass). GAN also takes an anchored `--rubric`.
- **`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`** raised for runs longer than ~8 experiments — see below.
- Whatever runtime the evaluator needs (interpreter, data, GPU, ...) — that is its concern, not the plugin's.

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
| `--score-cmd '<shell>'` | Numeric evaluator; LAST stdout line is a single number (needs `--direction`). |
| `--check-cmd '<shell>'` | Objective gate; exit 0 = pass. Use alone ("iterate until it passes") or as a hard filter with `--score-cmd`. |
| `--direction min\|max` | Whether a lower or higher score is better (with `--score-cmd`). |

Provide at least one evaluator (`--score-cmd` and/or `--check-cmd`), plus at least one of `--max-experiments <n>` / `--max-wall-clock <duration>`. (LLM-rubric evaluation is in `/autoresearch:gan`.)

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

## GAN tournament mode (`/autoresearch:gan`)

A different optimizer for when one sequential hill-climb is too slow or gets stuck in a local optimum. Instead of one change at a time, each **round** explores many in parallel and combines the best:

1. **Candidates** — fan out `--candidates` agents, each in an isolated git worktree, each starting from the current best content, each making one *distinct* change (guided by a different angle) and self-scoring.
2. **Judge** — an agent ranks the scored candidates and names concrete ideas from the runners-up worth grafting into the winner.
3. **Synthesize** — an agent combines the winner with those grafted ideas and **re-scores** the result. The scorer is the arbiter: synthesis only wins on a real score, never on plausibility.
4. **Iterate** — keep the best real score and repeat until `--target-score` is reached, `--max-rounds` is hit, two rounds pass with no improvement, or the token budget runs low.

It runs as a Claude Code **Workflow** (`workflows/gan.mjs`) — many parallel agents, real token cost — on a dedicated `autoresearch/gan-<tag>` branch, and commits the winning artifact there. Because a Workflow script cannot read the wall clock, GAN has **no `--max-wall-clock`**; bound it with `--max-rounds`. Because candidates pass full file contents as text, GAN requires a **single-file `--edit`**.

```
/autoresearch:gan feat1 \
  --prompt 'raise accuracy on the eval set' \
  --objective 'maximize accuracy on val.jsonl' \
  --edit prompt.txt \
  --score-cmd 'python eval_prompt.py --set val.jsonl' \
  --direction max --max-rounds 6 --target-score 0.95 --candidates 4
```

| GAN flag | Meaning |
|----------|---------|
| `--max-rounds <n>` | Hard bound on tournament rounds (required). |
| `--target-score <x>` | Stop early once the best numeric score reaches/passes this. |
| `--candidates <n>` | Parallel candidates per round (default 4). |
| `--check-cmd '<shell>'` | Objective gate; filters out failing candidates (or "find a passer" alone). |
| `--rubric '<criteria>'` | Criteria a 3-judge panel ranks candidates against. **Must** be paired with `--score-cmd` or `--check-cmd` (anti-reward-hack); the carried-over best competes each round so quality only ratchets up. |

Provide at least one evaluator (`--score-cmd`, `--check-cmd`, and/or anchored `--rubric`). The rest of the contract matches `start` (`--prompt`, `--objective`, `--edit`, `--direction`, `--readonly`, `--trial-timeout`).

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
