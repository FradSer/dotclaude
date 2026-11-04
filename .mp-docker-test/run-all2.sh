#!/usr/bin/env bash
# Second arm: plugin actually mounted (mount path fixed).
set -uo pipefail
BASE=/Users/FradSer/Developer/FradSer/dotclaude/.mp-docker-test
FIX=$BASE/fixtures
P=$BASE/prompts
run() { echo "### CASE $1 $(date +%T)"; bash "$BASE/run-case.sh" "$1" "$2" "$3" "${4:-}" "${5:-50}"; }

run p2-bdd "$FIX/fixture-app" "$P/p-bdd.txt" "" 60
run p2-tdd-gate "$FIX/fixture-app" "$P/p-tdd-gate.txt" "" 30
run p2-diagnosing "$FIX/buggy-app" "$P/p-diagnosing.txt" "" 60
run p2-wizard "$FIX/fixture-app" "$P/p-wizard.txt" "" 40
run p2-trigger "$FIX/buggy-app" "$P/p-trigger.txt" "" 60
echo "### ALL DONE $(date +%T)"
