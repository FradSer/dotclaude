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
| `/autoresearch:start <goal> [overrides]` | Give it a plain-language goal; it infers the artifact, evaluator, and bounds (asking only on true ambiguity), then runs the loop on a dedicated `autoresearch/<tag>` branch. |
| `/autoresearch:cancel` | Force-stop an active loop. Run from a **separate** session — the looping session is busy being re-prompted. |
| `/autoresearch:help` | Explain the plugin and its commands. |

`/autoresearch:start` is the single entry point. The loop runs cheap **sequential** rounds and, when it plateaus, escalates one round to a parallel **tournament** (the GAN engine: candidates → judge → synthesize → re-score) to break out — so you get overnight autonomy and tournament power from one command.

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

## The contract (mostly inferred)

Normally you just give a goal: `/autoresearch:start <plain-language goal>`. The command inspects the repo and infers everything below, asking only when the artifact or evaluator is genuinely ambiguous. Pass any flag to pin it as an override.

| Flag | Meaning |
|------|---------|
| `--edit <glob\|path>` | The ONLY artifact the agent may modify (inferred from the goal). |
| `--score-cmd '<shell>'` | Numeric evaluator; LAST stdout line is a single number (needs `--direction`). |
| `--check-cmd '<shell>'` | Objective gate; exit 0 = pass. Use alone ("iterate until it passes") or as a hard filter with `--score-cmd`. |
| `--rubric '<criteria>'` | Criteria an LLM judge panel applies when a plateau escalates to a tournament. **Must** be anchored by `--score-cmd` or `--check-cmd` (a judge-only loop reward-hacks). |
| `--direction min\|max` | Whether a lower or higher score is better (with `--score-cmd`). |
| `--prompt` / `--objective` | The goal and its measurable restatement (auto-filled from your goal). |

Need at least one evaluator (`--score-cmd`, `--check-cmd`, and/or anchored `--rubric`) plus a bound (`--max-experiments <n>` / `--max-wall-clock <duration>`) — the inference supplies sensible defaults.

Options: `--readonly <path>` (protect a path, repeatable), `--trial-timeout <duration>` (per-scorer-run hard limit, default `600`s), `--precheck '<shell>'` (precondition that must exit 0, repeatable), `--completion-promise '<text>'`, `--force` (replace an existing active state file).

## Experiment loop

Each experiment:

1. Choose one concrete change aimed at the objective.
2. Modify the `--edit` artifact (only that) and `git add <artifact>` — never `git add -A`.
3. `git commit`.
4. `timeout <trial-timeout> sh -c '<score-cmd>'`; read the **last** stdout line as the score.
5. Log to `results.tsv` (tab-separated: commit, score, status, description). Crashes are logged with score `NA` and always discarded.
6. Keep the commit only if the score is strictly better, in `--direction`, than the best `keep` score so far (`BEST_KEPT`). Otherwise `git reset --hard HEAD~1`.

`results.tsv` is kept **untracked** so a discard preserves the log; the plugin instructs the agent never to stage it.

## Hybrid loop: tournament on plateau

Sequential hill-climbing is cheap but stalls in local optima. When the loop plateaus — the last few rounds all non-improving — it escalates **one** round to a parallel tournament (the GAN engine, `workflows/gan.mjs`) to break out, then resumes sequential:

1. **Candidates** — fan out a few agents, each in an isolated git worktree, each starting from the current best, each making one *distinct* change and self-evaluating.
2. **Judge** — ranks the survivors (by score, or a 3-judge panel against your `--rubric`) and names ideas from the runners-up worth grafting.
3. **Synthesize** — combines the winner with those ideas and **re-evaluates**. The objective signal is the arbiter: synthesis only wins on a real re-measured result.
4. The winner is kept if it beats the current best; the loop returns to cheap sequential rounds.

A tournament round costs ~100k+ tokens, so escalation is reserved for genuine plateaus (single-file artifacts only — the engine passes full file contents between agents). This is why a `--rubric` lives here: independent judges can apply it without the self-judging reward-hack that a single sequential agent would fall into.

```
# qualitative goal — sequential by the wc anchor, escalating to a rubric tournament when stuck
/autoresearch:start make antigravity/README.md clearer and more concise
# inferred: --edit antigravity/README.md --score-cmd 'wc -w < ...' --direction min
#           --rubric '...clarity, no factual drift...' --check-cmd 'validate-plugin.py antigravity'
```

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
