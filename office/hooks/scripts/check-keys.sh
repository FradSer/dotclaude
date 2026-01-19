#!/bin/bash

# Enable strict mode for better error handling
set -euo pipefail

# Resolve script directory to find shared utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB_DIR="$SCRIPT_DIR/../../lib"

# Source shared utilities if available
if [[ -f "$LIB_DIR/utils.sh" ]]; then
  source "$LIB_DIR/utils.sh"
else
  # Fallback definitions if lib not found (should not happen in proper install)
  log_error() { echo "❌ Error: $1" >&2; }
  log_warning() { echo "⚠️  $1" >&2; }
fi

# Check for required API keys
MISSING=""

if [ -z "${SERPAPI_KEY:-}" ]; then
  MISSING="${MISSING}SERPAPI_KEY "
fi

if [ -z "${EXA_API_KEY:-}" ]; then
  MISSING="${MISSING}EXA_API_KEY "
fi

if [ -n "$MISSING" ]; then
  log_error "Missing API Keys for Office Plugin: ${MISSING}"
  echo ""
  echo "The patent-architect skill requires these keys to search for prior art."
  echo "Please set them in your shell configuration (e.g., ~/.zshrc) and restart the session:"
  echo ""
  echo "export SERPAPI_KEY='your_key_here'"
  echo "export EXA_API_KEY='your_key_here'"
  echo ""
  exit 1
fi

exit 0
