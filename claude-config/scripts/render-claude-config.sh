#!/bin/bash
# Render CLAUDE.md content from template + options.
# Usage:
#   render-claude-config.sh \
#     [--output-file <path>] \
#     [--target-file <path>] \
#     --include-tdd <true|false> \
#     --include-memory <true|false> \
#     [--enforce-validation <true|false>] \
#     [--validate-length-script <path>] \
#     [--base-template <path>] \
#     [--rules-file <path>] \
#     [--use-emojis <true|false>] \
#     [--developer-name <text>] \
#     [--developer-email <text>] \
#     [--stack "<language>:::<package_manager>"]...

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_BASE_TEMPLATE="$PLUGIN_ROOT/assets/claude-template-no-tdd.md"
DEFAULT_RULES_FILE="$PLUGIN_ROOT/assets/technology-stack-rules.md"
TDD_CORE_PRINCIPLE="$PLUGIN_ROOT/assets/claude-template-tdd-core-principle.md"
TDD_TESTING_STRATEGY="$PLUGIN_ROOT/assets/claude-template-tdd-testing-strategy.md"

BASE_TEMPLATE="$DEFAULT_BASE_TEMPLATE"
RULES_FILE="$DEFAULT_RULES_FILE"
OUTPUT_FILE=""
TARGET_FILE=""
INCLUDE_TDD=""
INCLUDE_MEMORY=""
USE_EMOJIS="false"
ENFORCE_VALIDATION="false"
VALIDATE_LENGTH_SCRIPT="$PLUGIN_ROOT/scripts/validate-length.sh"
DEVELOPER_NAME=""
DEVELOPER_EMAIL=""
declare -a STACKS=()
declare -a RULE_LANGUAGES=()
declare -a RULE_VALUES=()

die() {
  echo "ERROR: $*" >&2
  exit 1
}

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

normalize_bool() {
  case "$1" in
    true|1) printf 'true' ;;
    false|0) printf 'false' ;;
    *) die "invalid boolean '$1' (expected true/false)" ;;
  esac
}

require_file() {
  local path="$1"
  [ -f "$path" ] || die "file not found: $path"
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --base-template)
        [ "$#" -ge 2 ] || die "missing value for --base-template"
        BASE_TEMPLATE="$2"
        shift 2
        ;;
      --rules-file)
        [ "$#" -ge 2 ] || die "missing value for --rules-file"
        RULES_FILE="$2"
        shift 2
        ;;
      --output-file)
        [ "$#" -ge 2 ] || die "missing value for --output-file"
        OUTPUT_FILE="$2"
        shift 2
        ;;
      --target-file)
        [ "$#" -ge 2 ] || die "missing value for --target-file"
        TARGET_FILE="$2"
        shift 2
        ;;
      --include-tdd)
        [ "$#" -ge 2 ] || die "missing value for --include-tdd"
        INCLUDE_TDD="$(normalize_bool "$2")"
        shift 2
        ;;
      --include-memory)
        [ "$#" -ge 2 ] || die "missing value for --include-memory"
        INCLUDE_MEMORY="$(normalize_bool "$2")"
        shift 2
        ;;
      --use-emojis)
        [ "$#" -ge 2 ] || die "missing value for --use-emojis"
        USE_EMOJIS="$(normalize_bool "$2")"
        shift 2
        ;;
      --enforce-validation)
        [ "$#" -ge 2 ] || die "missing value for --enforce-validation"
        ENFORCE_VALIDATION="$(normalize_bool "$2")"
        shift 2
        ;;
      --validate-length-script)
        [ "$#" -ge 2 ] || die "missing value for --validate-length-script"
        VALIDATE_LENGTH_SCRIPT="$2"
        shift 2
        ;;
      --developer-name)
        [ "$#" -ge 2 ] || die "missing value for --developer-name"
        DEVELOPER_NAME="$2"
        shift 2
        ;;
      --developer-email)
        [ "$#" -ge 2 ] || die "missing value for --developer-email"
        DEVELOPER_EMAIL="$2"
        shift 2
        ;;
      --stack)
        [ "$#" -ge 2 ] || die "missing value for --stack"
        STACKS+=("$2")
        shift 2
        ;;
      *)
        die "unknown argument: $1"
        ;;
    esac
  done

  if [ -n "$OUTPUT_FILE" ] && [ -n "$TARGET_FILE" ]; then
    die "--output-file and --target-file are mutually exclusive"
  fi
  if [ -z "$OUTPUT_FILE" ] && [ -z "$TARGET_FILE" ]; then
    die "either --output-file or --target-file is required"
  fi
  [ -n "$INCLUDE_TDD" ] || die "--include-tdd is required"
  [ -n "$INCLUDE_MEMORY" ] || die "--include-memory is required"

  require_file "$BASE_TEMPLATE"
  require_file "$RULES_FILE"
  require_file "$TDD_CORE_PRINCIPLE"
  require_file "$TDD_TESTING_STRATEGY"
  require_file "$VALIDATE_LENGTH_SCRIPT"
}

guard_rules_urls() {
  if grep -Eq 'https?://' "$RULES_FILE"; then
    die "rules file contains URL(s), which is forbidden in generated technology sections"
  fi
}

apply_tdd_core_principle() {
  local input_file="$1"
  local output_file="$2"

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
      while ((getline line < tdd_file) > 0) {
        print line
      }
      close(tdd_file)
      tdd_inserted=1
      after_header=0
    }
    { print }
  ' "$input_file" > "$output_file"
}

replace_testing_strategy_section() {
  local input_file="$1"
  local output_file="$2"

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
    in_section && /^##/ {
      in_section=0
      print ""
    }
    in_section {
      next
    }
    { print }
  ' "$input_file" > "$output_file"
}

load_rules() {
  local line
  local language
  local rule
  local raw_language
  local raw_rule

  RULE_LANGUAGES=()
  RULE_VALUES=()

  while IFS= read -r line; do
    [[ "$line" == \|* ]] || continue

    IFS='|' read -r _ raw_language raw_rule _ <<< "$line"
    language="$(trim "$raw_language")"
    rule="$(trim "$raw_rule")"

    [ -n "$language" ] || continue
    [ -n "$rule" ] || continue
    [ "$language" != "Language" ] || continue
    [[ "$language" =~ ^[-:[:space:]]+$ ]] && continue
    [[ "$rule" =~ ^[-:[:space:]]+$ ]] && continue

    RULE_LANGUAGES+=("$language")
    RULE_VALUES+=("$rule")
  done < "$RULES_FILE"
}

lookup_rule() {
  local language="$1"
  local index
  for ((index=0; index<${#RULE_LANGUAGES[@]}; index++)); do
    if [ "${RULE_LANGUAGES[$index]}" = "$language" ]; then
      printf '%s' "${RULE_VALUES[$index]}"
      return
    fi
  done
}

render_profile_section() {
  local output_file="$1"

  : > "$output_file"
  if [ -z "$DEVELOPER_NAME" ] && [ -z "$DEVELOPER_EMAIL" ]; then
    return
  fi

  {
    echo "## Developer Profile"
    echo ""
    if [ -n "$DEVELOPER_NAME" ]; then
      echo "- **Name**: $DEVELOPER_NAME"
    fi
    if [ -n "$DEVELOPER_EMAIL" ]; then
      echo "- **Email**: $DEVELOPER_EMAIL"
    fi
  } > "$output_file"
}

parse_stack_entry() {
  local stack_entry="$1"
  local language
  local package_manager

  [[ "$stack_entry" == *":::"* ]] || die "invalid --stack value '$stack_entry' (expected <language>:::<package_manager>)"

  language="${stack_entry%%:::*}"
  package_manager="${stack_entry#*:::}"

  language="$(trim "$language")"
  package_manager="$(trim "$package_manager")"

  [ -n "$language" ] || die "invalid --stack value '$stack_entry': language is required"

  printf '%s\t%s' "$language" "$package_manager"
}

render_technology_section() {
  local output_file="$1"
  local stack_entry
  local parsed_stack
  local language
  local package_manager
  local rule

  : > "$output_file"

  {
    echo "## Technology Stack Configuration"
    echo ""

    if [ "${#STACKS[@]}" -gt 0 ]; then
      for stack_entry in "${STACKS[@]}"; do
        parsed_stack="$(parse_stack_entry "$stack_entry")"
        language="${parsed_stack%%$'\t'*}"
        package_manager="${parsed_stack#*$'\t'}"

        rule="$(lookup_rule "$language")"
        [ -n "$rule" ] || die "language '$language' not found in rules file"

        echo "### $language"
        echo ""
        if [ -n "$package_manager" ]; then
          echo "**Package Manager**: $package_manager"
        fi
        echo "- $rule"
        echo ""
      done
    else
      local index
      for ((index=0; index<${#RULE_LANGUAGES[@]}; index++)); do
        echo "### ${RULE_LANGUAGES[$index]}"
        echo ""
        echo "- ${RULE_VALUES[$index]}"
        echo ""
      done
    fi
  } > "$output_file"
}

render_memory_section() {
  local output_file="$1"

  : > "$output_file"
  if [ "$INCLUDE_MEMORY" != "true" ]; then
    return 0
  fi

  cat > "$output_file" <<'MEMORY'
## Memory
When discovering new project patterns, gotchas, or conventions during a session, append them to the relevant section of this file (Common Gotchas, Environment, or create a new section). Keep entries concise and deduplicated.
MEMORY
}

apply_emoji_style() {
  local file="$1"

  if [ "$USE_EMOJIS" = "true" ]; then
    return 0
  fi

  {
    printf '## Style Preferences\n\n'
    printf '%s\n' 'MUST NOT use emojis in generated content unless explicitly requested.'
    printf '%s\n' 'SHOULD NOT use emojis in code blocks, commands, file paths, or error messages.'
  } >> "$file"
}

insert_profile_after_title() {
  local input_file="$1"
  local profile_file="$2"
  local output_file="$3"

  if [ ! -s "$profile_file" ]; then
    cp "$input_file" "$output_file"
    return
  fi

  awk -v profile_file="$profile_file" '
    NR == 1 {
      print
      print ""
      while ((getline line < profile_file) > 0) {
        print line
      }
      close(profile_file)
      print ""
      next
    }
    NR == 2 && $0 == "" {
      next
    }
    { print }
  ' "$input_file" > "$output_file"
}

compose_final_output() {
  local base_file="$1"
  local profile_file="$2"
  local tech_file="$3"
  local memory_file="$4"
  local temp_with_profile="$5"

  insert_profile_after_title "$base_file" "$profile_file" "$temp_with_profile"

  cp "$temp_with_profile" "$temp_with_profile.final"

  if [ -s "$tech_file" ]; then
    printf '\n' >> "$temp_with_profile.final"
    cat "$tech_file" >> "$temp_with_profile.final"
  fi

  if [ -s "$memory_file" ]; then
    printf '\n' >> "$temp_with_profile.final"
    cat "$memory_file" >> "$temp_with_profile.final"
    printf '\n' >> "$temp_with_profile.final"
  fi

  mv "$temp_with_profile.final" "$temp_with_profile"
}

run_length_validation() {
  local file="$1"
  local validate_output
  local validate_status

  set +e
  validate_output="$(bash "$VALIDATE_LENGTH_SCRIPT" "$file" 2>&1)"
  validate_status=$?
  set -e

  printf '%s\n' "$validate_output"

  if [ "$ENFORCE_VALIDATION" = "true" ] && [ "$validate_status" -ne 0 ]; then
    die "length validation failed with status $validate_status"
  fi
}

write_output() {
  local rendered_file="$1"
  local backup_file
  local target_dir

  if [ -n "$OUTPUT_FILE" ]; then
    cp "$rendered_file" "$OUTPUT_FILE"
    return
  fi

  target_dir="$(dirname "$TARGET_FILE")"
  mkdir -p "$target_dir"

  if [ -f "$TARGET_FILE" ]; then
    backup_file="${TARGET_FILE}.bak"
    cp "$TARGET_FILE" "$backup_file"
    echo "Backup created: $backup_file"
  fi

  cp "$rendered_file" "$TARGET_FILE"
  echo "Wrote target: $TARGET_FILE"
}

main() {
  parse_args "$@"
  guard_rules_urls
  load_rules

  local temp_base
  local temp_tdd
  local temp_testing
  local profile_section
  local technology_section
  local memory_section
  local temp_composed

  temp_base="$(mktemp)"
  temp_tdd="$(mktemp)"
  temp_testing="$(mktemp)"
  profile_section="$(mktemp)"
  technology_section="$(mktemp)"
  memory_section="$(mktemp)"
  temp_composed="$(mktemp)"
  trap 'rm -f "${temp_base:-}" "${temp_tdd:-}" "${temp_testing:-}" "${profile_section:-}" "${technology_section:-}" "${memory_section:-}" "${temp_composed:-}"' EXIT

  cp "$BASE_TEMPLATE" "$temp_base"

  if [ "$INCLUDE_TDD" = "true" ]; then
    apply_tdd_core_principle "$temp_base" "$temp_tdd"
    replace_testing_strategy_section "$temp_tdd" "$temp_testing"
    cp "$temp_testing" "$temp_base"
  fi

  render_profile_section "$profile_section"
  render_technology_section "$technology_section"
  render_memory_section "$memory_section"

  compose_final_output "$temp_base" "$profile_section" "$technology_section" "$memory_section" "$temp_composed"
  apply_emoji_style "$temp_composed"
  write_output "$temp_composed"
}

main "$@"
