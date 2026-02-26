#!/bin/bash
# Render CLAUDE.md content from fragments + options.
# Usage:
#   render-claude-config.sh \
#     [--output-file <path>] \
#     [--target-file <path>] \
#     --testing-mode <bdd-tdd|bdd|tdd|none> \
#     --include-memory <true|false> \
#     --use-emojis <true|false> \
#     --developer-name <text> \
#     --developer-email <text> \
#     --stack "<language>:::<package_manager>"]...

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TDD_CORE_PRINCIPLE="$PLUGIN_ROOT/assets/testing-core/tdd-principle.md"
BDD_CORE_PRINCIPLE="$PLUGIN_ROOT/assets/testing-core/bdd-principle.md"
BDD_TDD_PRINCIPLE="$PLUGIN_ROOT/assets/testing-core/bdd-tdd-principle.md"
TDD_TESTING_STRATEGY="$PLUGIN_ROOT/assets/testing-core/testing-strategy.md"
STYLE_PREFERENCES="$PLUGIN_ROOT/assets/style-preferences.md"
BASE_FRAGMENTS_DIR="$PLUGIN_ROOT/assets/base-fragments"
CORE_PRINCIPLES_FILE="$BASE_FRAGMENTS_DIR/core-principles.md"
CODE_QUALITY_FILE="$BASE_FRAGMENTS_DIR/code-quality.md"
TESTING_STRATEGY_HEADER="$BASE_FRAGMENTS_DIR/testing-strategy-header.md"
TECH_FRAGMENTS_DIR="$PLUGIN_ROOT/assets/technology-fragments"

OUTPUT_FILE=""
TARGET_FILE=""
TESTING_MODE=""
INCLUDE_MEMORY=""
USE_EMOJIS="false"

DEVELOPER_NAME=""
DEVELOPER_EMAIL=""
declare -a STACKS=()

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
      --testing-mode)
        [ "$#" -ge 2 ] || die "missing value for --testing-mode"
        TESTING_MODE="$2"
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
  [ -n "$TESTING_MODE" ] || die "--testing-mode is required"
  [ -n "$INCLUDE_MEMORY" ] || die "--include-memory is required"

  require_file "$TDD_CORE_PRINCIPLE"
  require_file "$BDD_CORE_PRINCIPLE"
  require_file "$BDD_TDD_PRINCIPLE"
  require_file "$TDD_TESTING_STRATEGY"
  require_file "$STYLE_PREFERENCES"
  require_file "$CORE_PRINCIPLES_FILE"
  require_file "$CODE_QUALITY_FILE"
  require_file "$TESTING_STRATEGY_HEADER"
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

lookup_rule() {
  local language="$1"
  local fragment_file

  # Normalize language to lowercase for fragment lookup
  case "$language" in
    "Node.js") fragment_file="$TECH_FRAGMENTS_DIR/nodejs.md" ;;
    "Python") fragment_file="$TECH_FRAGMENTS_DIR/python.md" ;;
    "Rust") fragment_file="$TECH_FRAGMENTS_DIR/rust.md" ;;
    "Swift") fragment_file="$TECH_FRAGMENTS_DIR/swift.md" ;;
    "Go") fragment_file="$TECH_FRAGMENTS_DIR/go.md" ;;
    "Java") fragment_file="$TECH_FRAGMENTS_DIR/java.md" ;;
    *) return 1 ;;
  esac

  if [ -f "$fragment_file" ]; then
    cat "$fragment_file"
    return 0
  fi
  return 1
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

        rule="$(lookup_rule "$language")" || die "language '$language' not found in technology fragments"

        echo "### $language"
        echo ""
        if [ -n "$package_manager" ]; then
          echo "**Package Manager**: $package_manager"
        fi
        echo "- $rule"
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

  cat "$STYLE_PREFERENCES" >> "$file"
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

  local temp_output
  local temp_core_principles
  local profile_section
  local technology_section
  local memory_section

  temp_output="$(mktemp)"
  temp_core_principles="$(mktemp)"
  profile_section="$(mktemp)"
  technology_section="$(mktemp)"
  memory_section="$(mktemp)"
  trap 'rm -f "${temp_output:-}" "${temp_core_principles:-}" "${profile_section:-}" "${technology_section:-}" "${memory_section:-}"' EXIT

  # Build core principles with testing principle first
  {
    case "$TESTING_MODE" in
      bdd-tdd)
        cat "$BDD_TDD_PRINCIPLE"
        ;;
      bdd)
        cat "$BDD_CORE_PRINCIPLE"
        ;;
      tdd)
        cat "$TDD_CORE_PRINCIPLE"
        ;;
      none)
        ;;
    esac
    if [ "$TESTING_MODE" != "none" ]; then
      cat "$CORE_PRINCIPLES_FILE"
    else
      cat "$CORE_PRINCIPLES_FILE"
    fi
  } > "$temp_core_principles"

  # Build document from fragments
  {
    # Title
    echo "# Claude Development Guidelines"
    echo ""

    # Developer Profile
    render_profile_section "$profile_section"
    if [ -s "$profile_section" ]; then
      cat "$profile_section"
      echo ""
    fi

    # Core Principles
    echo "## Core Principles"
    echo ""
    cat "$temp_core_principles"
    echo ""

    # Code Quality
    echo "## Code Quality"
    echo ""
    cat "$CODE_QUALITY_FILE"
    echo ""

    # Testing Strategy (only for tdd and bdd-tdd modes)
    case "$TESTING_MODE" in
      tdd|bdd-tdd)
        echo "### Testing Strategy"
        echo ""
        cat "$TDD_TESTING_STRATEGY"
        echo ""
        ;;
      *)
        ;;
    esac

    # Technology Stack Configuration
    render_technology_section "$technology_section"
    if [ -s "$technology_section" ]; then
      cat "$technology_section"
    fi

  } > "$temp_output"

  # Memory section
  render_memory_section "$memory_section"
  if [ -s "$memory_section" ]; then
    printf '\n' >> "$temp_output"
    cat "$memory_section" >> "$temp_output"
    printf '\n' >> "$temp_output"
  fi

  apply_emoji_style "$temp_output"
  write_output "$temp_output"
}

main "$@"