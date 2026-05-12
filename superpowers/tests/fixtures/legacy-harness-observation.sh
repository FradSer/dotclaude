#!/usr/bin/env bash
# legacy-harness-observation.sh — verbatim capture of the pre-migration
# bash block that retrospective Phase 5c uses to append `component_unsupported`
# / `component_unknown` rows to docs/retros/harness-observations.jsonl.
#
# Source: retrospective/SKILL.md Phase 5c refusal gate (line 146) and the
# bdd-specs.md §1.3 canonical form. The `jq -nc` invocation, --arg order,
# and field order in the filter MUST stay byte-equal to the SKILL.md
# template — task 006 compares this script's output against the new
# log_harness_observation output to prove migration parity.
#
# Usage:
#   legacy-harness-observation.sh <log_file> <event> <component> <retrospective_id> <timestamp>
#
# All five arguments are required. <timestamp> is passed in so parity
# tests can substitute a deterministic value rather than calling `date`.

log_file=$1
event=$2
component=$3
retrospective_id=$4
timestamp=$5

mkdir -p "$(dirname "$log_file")"

jq -nc \
  --arg event "$event" \
  --arg c "$component" \
  --arg ts "$timestamp" \
  --arg retro "$retrospective_id" \
  '{event:$event, component:$c, timestamp:$ts, retrospective_id:$retro}' \
  >> "$log_file"
