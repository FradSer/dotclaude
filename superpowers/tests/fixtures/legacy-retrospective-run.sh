#!/usr/bin/env bash
# legacy-retrospective-run.sh — verbatim capture of the pre-migration
# bash block that retrospective Phase 6 closure uses to append a
# `retrospective_run` row to docs/retros/evolution-log.jsonl.
#
# Source: retrospective/SKILL.md Phase 6 closure (lines 176-191) and
# references/evolution-protocol.md "Retrospective-run event" template
# (lines 101-125). The envelope keys (event, timestamp, plans_analyzed,
# report, proposals_approved, proposals_rejected, disable_test,
# self_value) MUST stay in this exact order — task 006 compares this
# script's output against log_evolution_event output to prove migration
# parity.
#
# Usage:
#   legacy-retrospective-run.sh <log_file> <timestamp> <report> <self_value_json> \
#                                [plans_analyzed_json] [proposals_approved] \
#                                [proposals_rejected] [disable_test]
#
# Defaults:
#   plans_analyzed_json   = "[]"
#   proposals_approved    = 0
#   proposals_rejected    = 0
#   disable_test          = null (literal JSON null, not the string "null")
#
# <self_value_json> is a complete JSON object (e.g.
# '{"proposals_total":0,"disable_test_set":false,"consecutive_zero_change":1}').

log_file=$1
timestamp=$2
report=$3
self_value_json=$4
plans_analyzed_json=${5:-[]}
proposals_approved=${6:-0}
proposals_rejected=${7:-0}
disable_test=${8:-}

mkdir -p "$(dirname "$log_file")"

if [[ -z "$disable_test" ]]; then
  jq -nc \
    --arg event "retrospective_run" \
    --arg ts "$timestamp" \
    --argjson plans "$plans_analyzed_json" \
    --arg report "$report" \
    --argjson approved "$proposals_approved" \
    --argjson rejected "$proposals_rejected" \
    --argjson sv "$self_value_json" \
    '{event:$event, timestamp:$ts, plans_analyzed:$plans, report:$report, proposals_approved:$approved, proposals_rejected:$rejected, disable_test:null, self_value:$sv}' \
    >> "$log_file"
else
  jq -nc \
    --arg event "retrospective_run" \
    --arg ts "$timestamp" \
    --argjson plans "$plans_analyzed_json" \
    --arg report "$report" \
    --argjson approved "$proposals_approved" \
    --argjson rejected "$proposals_rejected" \
    --arg disable "$disable_test" \
    --argjson sv "$self_value_json" \
    '{event:$event, timestamp:$ts, plans_analyzed:$plans, report:$report, proposals_approved:$approved, proposals_rejected:$rejected, disable_test:$disable, self_value:$sv}' \
    >> "$log_file"
fi
