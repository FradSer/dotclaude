# Example: combinatorial solver tuning (non-ML)

Tune a solver's configuration to minimize a tour length / objective gap. The
artifact is a YAML config (not code), runs are long, so a wall-clock bound
governs instead of an iteration count.

```
/autoresearch:start \
  --prompt 'Tune the heuristics in config/solver.yaml to find shorter tours.' \
  --objective 'minimize tour length on the benchmark instances' \
  --edit config/solver.yaml \
  --score-cmd 'python run_solver.py --config config/solver.yaml | tail -1' \
  --direction min \
  --max-wall-clock 2h \
  --trial-timeout 5m
```

`run_solver.py` runs the benchmark and prints the tour length as its last
stdout line. `--trial-timeout 5m` hard-kills any single solver run that hangs
so one trial can't starve the 2h budget.
