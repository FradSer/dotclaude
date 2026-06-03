# Example: ML training (parity with karpathy/autoresearch)

Reproduces the original ML behavior exactly, now expressed through the generic
contract. Edit `train.py`, never touch `prepare.py`/`evaluate_bpb`, minimize
`val_bpb` read from the run log.

```
/autoresearch:start \
  --prompt 'Lower validation bits-per-byte by improving the model in train.py.' \
  --objective 'minimize val_bpb' \
  --edit train.py \
  --readonly prepare.py --readonly evaluate_bpb \
  --score-cmd 'timeout 600 uv run train.py >run.log 2>&1; grep "^val_bpb:" run.log | awk "{print \$2}"' \
  --direction min \
  --max-wall-clock 8h
```

Notes:
- The scorer runs the training and prints `val_bpb` as its last stdout line.
- `--readonly` keeps the data prep and the evaluation function off-limits, the
  way the original hardcoded "never modify prepare.py / evaluate_bpb".
- Requires a GPU + `uv` + `uv run prepare.py` done once — those are the
  scorer's requirements, not the plugin's.
