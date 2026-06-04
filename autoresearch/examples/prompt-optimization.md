# Example: prompt optimization (non-ML)

Iterate on a prompt file to maximize accuracy on a held-out eval set. The
artifact is a plain text file (not source code), and the scorer is a separate
evaluation command — demonstrating that the loop does not assume
"edit-a-file-then-run-the-edited-file".

```
/autoresearch:start \
  --prompt 'Rewrite prompt.txt to raise accuracy on the validation set without overfitting to its examples.' \
  --objective 'maximize accuracy on val.jsonl' \
  --edit prompt.txt \
  --score-cmd 'python eval_prompt.py --prompt prompt.txt --set val.jsonl' \
  --direction max \
  --max-experiments 30 \
  --completion-promise 'PROMPT CONVERGED'
```

`eval_prompt.py` runs the prompt against `val.jsonl` (fixed eval or LLM judge)
and prints accuracy as its last stdout line. A noisy judge should average
several runs internally so the single number is stable.
