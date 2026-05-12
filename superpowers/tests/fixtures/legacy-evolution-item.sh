#!/usr/bin/env bash
# legacy-evolution-item.sh — verbatim capture of the pre-migration bash
# block that retrospective Phase 4 step 3 uses to append item_added /
# item_removed / item_modified / item_promoted rows to
# docs/retros/evolution-log.jsonl.
#
# Source: retrospective/SKILL.md Phase 4 step 3 (line 104) and
# references/evolution-protocol.md "Proposal events" template
# (lines 83-97). The envelope keys (timestamp, event, mode, item_id,
# description, rationale, driving_plans, checklist_version,
# retrospective_report) MUST stay in this exact order.
#
# Usage:
#   legacy-evolution-item.sh <log_file> <event_type> <description> \
#       <rationale> <driving_plan> <checklist_version> \
#       <retrospective_report> <timestamp> \
#       [mode] [item_id]
#
# <event_type> must be one of: item_added | item_removed | item_modified
# | item_promoted. <driving_plan> is a single plan path; it is wrapped
# into a one-element JSON array to match the schema. Defaults:
#   mode    = code
#   item_id = ITEM-DEFAULT

log_file=$1
event_type=$2
description=$3
rationale=$4
driving_plan=$5
checklist_version=$6
retrospective_report=$7
timestamp=$8
mode=${9:-code}
item_id=${10:-ITEM-DEFAULT}

mkdir -p "$(dirname "$log_file")"

# Wrap the single driving plan into a JSON array to match the
# evolution-protocol.md schema (`driving_plans` is array-typed).
plans_json=$(jq -nc --arg p "$driving_plan" '[$p]')

jq -nc \
  --arg ts "$timestamp" \
  --arg event "$event_type" \
  --arg mode "$mode" \
  --arg id "$item_id" \
  --arg d "$description" \
  --arg r "$rationale" \
  --argjson plans "$plans_json" \
  --arg v "$checklist_version" \
  --arg report "$retrospective_report" \
  '{timestamp:$ts, event:$event, mode:$mode, item_id:$id, description:$d, rationale:$r, driving_plans:$plans, checklist_version:$v, retrospective_report:$report}' \
  >> "$log_file"
