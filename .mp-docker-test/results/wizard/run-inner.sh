#!/usr/bin/env bash
set -x
cd /work
claude \
  $PLUGIN_FLAG \
  --dangerously-skip-permissions \
  --model "$MP_MODEL" \
  --output-format stream-json --verbose \
  --max-turns "$MP_MAXT" \
  -p "$(cat /work/PROMPT.txt)" \
  > /work/trace.jsonl 2>/work/stderr.log
echo "inner-exit=$?"
