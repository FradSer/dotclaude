#!/bin/bash

# Shared utility functions for Office Plugin scripts
# This library provides common logging, error handling, and parsing functions

# Log error message (red icon)
# Usage: log_error "message" ["context_line1"...]
log_error() {
  local msg="$1"
  shift

  echo "❌ Error: $msg" >&2
  for context in "$@"; do
    echo "   $context" >&2
  done
}

# Log success message (green icon)
log_success() {
  echo "✅ $1"
}

# Log fatal error and exit with code 1
# Usage: log_fatal "message" ["context"...]
log_fatal() {
  log_error "$@"
  exit 1
}

# Validate required environment variable
require_env() {
  local var_name="$1"
  local var_value="${!var_name}"

  if [ -z "$var_value" ]; then
    log_fatal "Required environment variable '$var_name' is not set"
  fi
}
