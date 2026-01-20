#!/bin/bash
# Validates CLAUDE.md length against best practices
# Best practice: 1500-3000 words for optimal context usage

set -euo pipefail

FILE="${1:-$HOME/.claude/CLAUDE.md}"

if [[ ! -f "$FILE" ]]; then
  echo "ERROR: File not found: $FILE"
  exit 1
fi

# Count words (excluding frontmatter if present)
WORD_COUNT=$(grep -v '^---$' "$FILE" | wc -w | tr -d ' ')

# Best practice ranges
MIN_WORDS=800
OPTIMAL_MIN=1500
OPTIMAL_MAX=3000
MAX_WORDS=5000

echo "Word count: $WORD_COUNT"

if [[ $WORD_COUNT -lt $MIN_WORDS ]]; then
  echo "STATUS: TOO_SHORT"
  echo "RECOMMENDATION: Add more details or examples (minimum: $MIN_WORDS words)"
  exit 2
elif [[ $WORD_COUNT -ge $MIN_WORDS && $WORD_COUNT -lt $OPTIMAL_MIN ]]; then
  echo "STATUS: ACCEPTABLE"
  echo "RECOMMENDATION: Consider adding more context (optimal: $OPTIMAL_MIN-$OPTIMAL_MAX words)"
  exit 0
elif [[ $WORD_COUNT -ge $OPTIMAL_MIN && $WORD_COUNT -le $OPTIMAL_MAX ]]; then
  echo "STATUS: OPTIMAL"
  echo "RECOMMENDATION: Perfect length for context efficiency"
  exit 0
elif [[ $WORD_COUNT -gt $OPTIMAL_MAX && $WORD_COUNT -le $MAX_WORDS ]]; then
  echo "STATUS: TOO_LONG"
  echo "RECOMMENDATION: Consider trimming to improve context efficiency (optimal: $OPTIMAL_MIN-$OPTIMAL_MAX words)"
  exit 3
else
  echo "STATUS: EXCESSIVE"
  echo "RECOMMENDATION: Significantly trim content (current: $WORD_COUNT, maximum: $MAX_WORDS words)"
  exit 4
fi
