#!/usr/bin/env bash
# run-case.sh <case> <fixture-dir> <prompt-file> [--no-plugin] [MAXT]
# Runs one headless Claude Code session against the mattpocock plugin inside Docker.
set -uo pipefail
BASE="$(cd "$(dirname "$0")" && pwd)"
CASE="$1"; FIXTURE="$2"; PROMPT="$3"; MODE="${4:-}"; MAXT="${5:-50}"
OUT="$BASE/results/$CASE"
rm -rf "$OUT"; mkdir -p "$OUT/work/home"

mkdir -p "$OUT/work/fixture-app"
cp -r "$FIXTURE"/. "$OUT/work/fixture-app"/
(
  cd "$OUT/work/fixture-app"
  git init -q
  git add -A
  git -c user.email=t@t -c user.name=t commit -qm "init fixture"
) >/dev/null 2>&1

cp "$PROMPT" "$OUT/work/PROMPT.txt"

PLUGIN_FLAG=""
[[ "$MODE" == "--no-plugin" ]] || PLUGIN_FLAG="--plugin-dir /plugin/mattpocock"

cat > "$OUT/run-inner.sh" <<'INNER'
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
INNER

docker run --rm \
  -v "$OUT/work:/work" \
  -v "$OUT/run-inner.sh:/inner.sh:ro" \
  -v "$BASE/../mattpocock:/plugin/mattpocock:ro" \
  -e HOME=/work/home \
  -e ANTHROPIC_BASE_URL=http://10.10.0.195:8317 \
  -e ANTHROPIC_API_KEY=sk-dummy -e ANTHROPIC_AUTH_TOKEN=sk-dummy \
  -e ANTHROPIC_DEFAULT_SONNET_MODEL=qwen3.8-flash \
  -e ANTHROPIC_DEFAULT_OPUS_MODEL=qwen3.8-max \
  -e ANTHROPIC_DEFAULT_HAIKU_MODEL=qwen3.8-flash \
  -e ANTHROPIC_DEFAULT_FABLE_MODEL=qwen3.8-max \
  -e CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 \
  -e PLUGIN_FLAG="$PLUGIN_FLAG" \
  -e MP_MODEL=qwen3.8-max \
  -e MP_MAXT="$MAXT" \
  --user "$(id -u):$(id -g)" \
  mp-e2e-test bash /inner.sh

echo "== $CASE done; trace size:"
wc -c "$OUT/work/trace.jsonl" 2>/dev/null || echo "(no trace)"
