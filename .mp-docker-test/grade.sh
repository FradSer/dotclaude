#!/usr/bin/env bash
# grade.sh <case> — prints grader facts from a finished run
set -uo pipefail
BASE=/Users/FradSer/Developer/FradSer/dotclaude/.mp-docker-test
CASE="$1"; W="$BASE/results/$CASE/work"
T="$W/trace.jsonl"
[[ -f "$T" ]] || { echo "$CASE: NO TRACE"; exit 1; }

echo "== $CASE =="
echo "-- skill calls (name -> ok/error):"
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use" and .name=="Skill") | [.id, (.input.skill // .input.name // "?")] | @tsv' "$T" 2>/dev/null \
  | while IFS=$'\t' read -r id name; do
      ok=$(jq -r --arg id "$id" 'select(.type=="user") | .message.content[]? | select(.type=="tool_result" and .tool_use_id==$id) | (.content|tostring) | if test("Unknown skill|not found|error") then "ERROR" else "ok" end' "$T" 2>/dev/null | head -1)
      echo "   $name -> ${ok:-?}"
    done

echo "-- other skill loads in result (did model fall back to reading files?):"
grep -o 'skills/engineering/[a-z-]*\|Read.*SKILL.md' "$T" | sort -u | head -8

echo "-- tool counts:"
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | .name' "$T" | sort | uniq -c

echo "-- AskUserQuestion attempts:"
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use" and .name=="AskUserQuestion") | .input' "$T" | head -3

echo "-- files created:"
find "$W" -newer "$W/PROMPT.txt" -type f -not -path "*/.git/*" -not -name "PROMPT.txt" -not -name "trace.jsonl" -not -name "stderr.log" -not -path "*/home/*" | sed "s|$W/||"

echo "-- result text (tail):"
jq -r 'select(.type=="result") | .result' "$T" | tail -15
