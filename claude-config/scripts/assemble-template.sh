#!/bin/bash
# Assemble Claude template from base template and optional TDD components
# Usage: assemble-template.sh <base_template> <include_tdd> <output_file> <plugin_root>

set -euo pipefail

BASE_TEMPLATE="$1"
INCLUDE_TDD="$2"
OUTPUT_FILE="$3"
PLUGIN_ROOT="$4"

TDD_CORE_PRINCIPLE="${PLUGIN_ROOT}/assets/claude-template-tdd-core-principle.md"
TDD_TESTING_STRATEGY="${PLUGIN_ROOT}/assets/claude-template-tdd-testing-strategy.md"

# Create temporary file
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# Copy base template
cp "$BASE_TEMPLATE" "$TEMP_FILE"

if [ "$INCLUDE_TDD" = "true" ] || [ "$INCLUDE_TDD" = "1" ]; then
  # Insert TDD core principle as first item in Core Principles section
  # Insert TDD content right after "## Core Principles" header, before any existing items
  awk -v tdd_file="$TDD_CORE_PRINCIPLE" '
    BEGIN { after_header=0; tdd_inserted=0 }
    /^## Core Principles$/ {
      print
      after_header=1
      next
    }
    after_header && /^$/ {
      print
      next
    }
    after_header && /^-/ && !tdd_inserted {
      # First list item found, insert TDD before it
      while ((getline line < tdd_file) > 0) {
        print line
      }
      close(tdd_file)
      tdd_inserted=1
      after_header=0
    }
    { print }
  ' "$TEMP_FILE" > "${TEMP_FILE}.tmp" && mv "${TEMP_FILE}.tmp" "$TEMP_FILE"

  # Replace Testing Strategy section
  awk -v testing_file="$TDD_TESTING_STRATEGY" '
    BEGIN { in_section=0 }
    /^### Testing Strategy$/ {
      print
      print ""
      while ((getline line < testing_file) > 0) {
        print line
      }
      close(testing_file)
      in_section=1
      next
    }
    in_section && /^###/ {
      in_section=0
    }
    in_section {
      next
    }
    { print }
  ' "$TEMP_FILE" > "${TEMP_FILE}.tmp" && mv "${TEMP_FILE}.tmp" "$TEMP_FILE"
fi

# Write output
cp "$TEMP_FILE" "$OUTPUT_FILE"
