#!/usr/bin/env bash
set -uo pipefail
BASE=/Users/FradSer/Developer/FradSer/dotclaude/.mp-docker-test
FIX=$BASE/fixtures
P=$BASE/prompts
run() { echo "### CASE $1 $(date +%T)"; bash "$BASE/run-case.sh" "$1" "$2" "$3" "${4:-}" "${5:-50}"; }

run bdd-redgreen "$FIX/fixture-app" "$P/p-bdd.txt" "" 60
run tdd-gate "$FIX/fixture-app" "$P/p-tdd-gate.txt" "" 30
run diagnosing "$FIX/buggy-app" "$P/p-diagnosing.txt" "" 60
run wizard "$FIX/fixture-app" "$P/p-wizard.txt" "" 40
echo "### ALL DONE $(date +%T)"
