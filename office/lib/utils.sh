#!/bin/bash

# Shared utility functions for Office Plugin scripts
# This library provides common logging, error handling, and parsing functions

# Extract a field value from YAML frontmatter in a file
# Usage: extract_frontmatter_field "file.md" "field_name"
extract_frontmatter_field() {
    local file="$1"
    local field="$2"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    # Extract frontmatter block
    local frontmatter
    frontmatter=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$file")

    if [[ -z "$frontmatter" ]]; then
        return 1
    fi

    # Extract specific field and strip quotes
    echo "$frontmatter" | grep "^${field}:" | sed "s/${field}: *//" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\\(.*\\)'$/\\1/"
}

# Log warning message (yellow icon)
# Usage: log_warning "message" ["context_line1" "context_line2"...]
log_warning() {
  local msg="$1"
  shift

  echo "⚠️  $msg" >&2
  for context in "$@"; do
    echo "   $context" >&2
  done
}

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

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Validate required environment variable
require_env() {
  local var_name="$1"
  local var_value="${!var_name}"
  
  if [ -z "$var_value" ]; then
    log_fatal "Required environment variable '$var_name' is not set"
  fi
}

# Check if a value is a non-negative integer
# Usage: is_uint "value"
is_uint() {
    [[ "$1" =~ ^[0-9]+$ ]]
}
