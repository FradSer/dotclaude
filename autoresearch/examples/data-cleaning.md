# Example: data-cleaning rules (non-ML)

Optimize a data-cleaning script to maximize F1 against a labeled sample. The
scorer is a separate script that prints F1 as its last line; a precision floor
is enforced inside the scorer (emit a penalized score if precision < 0.90).

```
/autoresearch:start clean1 \
  --prompt 'Improve the cleaning/normalization rules in clean.py to better match the gold labels.' \
  --objective 'maximize F1 while keeping precision >= 0.90' \
  --edit clean.py \
  --readonly score.sh --readonly sample.csv \
  --score-cmd 'bash score.sh' \
  --direction max \
  --max-experiments 20
```

`score.sh` (you provide it) runs `clean.py` over `sample.csv`, compares to gold
labels, and prints one number (F1, or a penalized value when the precision
floor is violated) as its final stdout line.
