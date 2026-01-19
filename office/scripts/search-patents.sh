#!/bin/bash

# Patent Search Script
# Searches for prior art using SerpAPI or Exa.ai

set -euo pipefail

# Resolve script directory to find shared utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB_DIR="$SCRIPT_DIR/../lib"

# Source shared utilities if available
if [[ -f "$LIB_DIR/utils.sh" ]]; then
  source "$LIB_DIR/utils.sh"
else
  # Fallback definitions
  log_error() { echo "❌ Error: $1" >&2; }
  log_success() { echo "✅ $1"; }
fi

# Default values
ENGINE="serpapi"
NUM_RESULTS=10
QUERY=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'HELP_EOF'
Patent Search - Search for prior art patents

USAGE:
  search-patents.sh [QUERY...] [OPTIONS]

ARGUMENTS:
  QUERY...    Search query (can be multiple words)

OPTIONS:
  --engine <serpapi|exa>  Search engine to use (default: serpapi)
  --num <n>               Number of results (default: 10)
  -h, --help              Show this help message

EXAMPLES:
  search-patents.sh mobile payment authentication
  search-patents.sh "biometric verification" --engine exa --num 5
  search-patents.sh AI image recognition --engine serpapi

ENVIRONMENT VARIABLES:
  SERPAPI_KEY   Required for SerpAPI engine
  EXA_API_KEY   Required for Exa.ai engine
HELP_EOF
      exit 0
      ;;
    --engine)
      if [[ -z "${2:-}" ]]; then
        log_error "--engine requires an argument (serpapi or exa)"
        exit 1
      fi
      ENGINE="$2"
      shift 2
      ;;
    --num)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
        log_error "--num requires a positive integer"
        exit 1
      fi
      NUM_RESULTS="$2"
      shift 2
      ;;
    *)
      # Collect query parts
      if [[ -n "$QUERY" ]]; then
        QUERY="$QUERY $1"
      else
        QUERY="$1"
      fi
      shift
      ;;
  esac
done

# Validate query
if [[ -z "$QUERY" ]]; then
  log_error "No search query provided"
  echo ""
  echo "Usage: search-patents.sh <query> [--engine serpapi|exa] [--num N]"
  echo "Run with --help for more information."
  exit 1
fi

# URL encode the query
ENCODED_QUERY=$(printf '%s' "$QUERY" | jq -sRr @uri)

# Execute search based on engine
case "$ENGINE" in
  serpapi)
    if [[ -z "${SERPAPI_KEY:-}" ]]; then
      log_error "SERPAPI_KEY environment variable is not set"
      exit 1
    fi
    echo "🔍 Searching Google Patents via SerpAPI for: $QUERY"
    curl -s "https://serpapi.com/search.json?engine=google_patents&q=$ENCODED_QUERY&api_key=${SERPAPI_KEY}&num=$NUM_RESULTS"
    ;;
  exa)
    if [[ -z "${EXA_API_KEY:-}" ]]; then
      log_error "EXA_API_KEY environment variable is not set"
      exit 1
    fi
    echo "🔍 Searching patents via Exa.ai for: $QUERY"
    curl -s -X POST 'https://api.exa.ai/search' \
      -H "x-api-key: ${EXA_API_KEY}" \
      -H 'Content-Type: application/json' \
      -d "{\"query\": \"$QUERY\", \"type\": \"neural\", \"numResults\": $NUM_RESULTS, \"includeDomains\": [\"patents.google.com\"]}"
    ;;
  *)
    log_error "Unknown engine: $ENGINE (use serpapi or exa)"
    exit 1
    ;;
esac

echo ""
log_success "Search complete"
