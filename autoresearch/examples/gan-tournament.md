# Example: GAN tournament (prompt optimization)

Optimize a single prompt file toward a target accuracy using the parallel
tournament instead of the sequential ralph-loop. Use this when one-change-at-a-
time hill climbing is too slow or keeps stalling in a local optimum.

```
/autoresearch:gan promptv2 \
  --prompt 'Rewrite prompt.txt to raise accuracy on the validation set without overfitting to its examples.' \
  --objective 'maximize accuracy on val.jsonl' \
  --edit prompt.txt \
  --score-cmd 'python eval_prompt.py --prompt prompt.txt --set val.jsonl' \
  --direction max \
  --max-rounds 6 \
  --target-score 0.95 \
  --candidates 4
```

What happens each round:

1. Four candidate agents each take the current best `prompt.txt`, make one
   distinct rewrite (one minimal, one aggressive, one different approach, one
   targeting the current weakness), and run `eval_prompt.py` in their own
   worktree.
2. A judge ranks the four by accuracy and notes which phrasings from the
   runners-up look worth borrowing.
3. A synthesis agent grafts those phrasings onto the top candidate and re-runs
   `eval_prompt.py`. It is kept only if its real accuracy beats the top candidate.
4. The best `prompt.txt` carries into the next round.

The run stops at the first of: accuracy >= 0.95, six rounds, two rounds with no
improvement, or a low token budget. The winning `prompt.txt` is committed on the
`autoresearch/gan-promptv2` branch; `gan-results.tsv` logs each round's scores.

Notes:
- `eval_prompt.py` must print accuracy as its last stdout line (a noisy LLM judge
  should average several runs internally so the number is stable).
- GAN requires a single file for `--edit`. For multi-file or glob targets, use
  `/autoresearch:start` (the sequential ralph-loop) instead.
- This spawns many parallel agents per round — expect meaningfully higher token
  cost than the sequential loop, in exchange for breadth and synthesis.

## Beyond a numeric scorer: gate + rubric

When "better" is not a single number — e.g. refactoring a module where the only
hard requirement is "tests still pass" and the rest is judgement — combine an
objective **gate** with an LLM **rubric**:

```
/autoresearch:gan refactor1 \
  --prompt 'Refactor src/parser.ts for clarity without changing behavior.' \
  --objective 'cleaner, simpler parser; all tests green' \
  --edit src/parser.ts \
  --check-cmd 'pnpm test parser' \
  --rubric 'Prefer fewer branches, clear names, no dead code, smaller functions; behavior must be unchanged.' \
  --max-rounds 5 --candidates 4
```

Each round, only candidates whose tests pass (`--check-cmd` exit 0) survive; a
3-judge panel then ranks the survivors against the rubric, and the current best
is carried into the panel so quality only ratchets up. The rubric is **anchored**
by the gate — a judge-only loop would reward-hack, so `--rubric` requires a
`--check-cmd` or `--score-cmd`. There is no `--target-score` here (the rubric has
no fixed scale); the run stops at `--max-rounds` or two rounds with no improvement.

To "iterate until it passes" with no quality judging at all, use the gate alone
(`--check-cmd`, no `--rubric`/`--score-cmd`): GAN searches for a passing variant
and stops at the first one.
