#!/bin/bash
# Sync script for dotclaude repository
# Syncs CLAUDE.md file to https://github.com/FradSer/dotclaude
set -e
#===============================================================================
# CONFIGURATION AND CONSTANTS
#===============================================================================
# Repository configuration
readonly REPO_URL="git@github.com:FradSer/dotclaude.git"
readonly REPO_URL_HTTPS="https://github.com/FradSer/dotclaude.git"
readonly TEMP_DIR="/tmp/dotclaude-sync"
readonly BRANCH="main"
# Items for sync operations - only CLAUDE.md
readonly SYNC_ITEMS=("CLAUDE.md:file")
readonly EXCLUDE_PATTERNS=(".DS_Store")
# Colors for output
readonly RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NC='\033[0m'
# Menu choice constants
readonly MENU_CHOICE_USE_LOCAL=1
readonly MENU_CHOICE_USE_REPO=2
readonly MENU_CHOICE_SKIP=3
readonly MENU_CHOICE_SHOW_DIFF=4
# Return status constants
readonly STATUS_NO_CHANGES=0
readonly STATUS_CHANGES_MADE=1
# Runtime options (overridable by CLI flags)
NON_INTERACTIVE=false
PREFER_MODE="repo"       # valid: local | repo; default: repo
TARGET_BRANCH="$BRANCH" # can be overridden by --branch
FORCE_HTTPS=false        # force HTTPS clone instead of SSH
declare -a EXTRA_EXCLUDES
#===============================================================================
# UTILITY FUNCTIONS
#===============================================================================
# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
# Get best available diff tool
get_diff_tool() {
    for tool in colordiff git diff; do
        command -v "$tool" >/dev/null 2>&1 && echo "$tool" && return
    done
    log_error "No diff tools found!" && exit 1
}

# Check if path exists based on type - unified path checking
path_exists() {
    local path="$1" is_dir="$2"
    if [ "$is_dir" = true ]; then
        [ -d "$path" ]
    else
        [ -f "$path" ]
    fi
}
# Validate item exists at path - simplified version
validate_item_at_path() {
    local item="$1" type="$2" base_path="$3"
    local full_path="$base_path/$item"
    local is_dir=$([ "$type" = "dir" ] && echo true || echo false)
    
    if path_exists "$full_path" "$is_dir"; then
        return 0
    else
        log_error "$item $type not found at $full_path"
        return 1
    fi
}

# Unified path management function
manage_path() {
    local path="$1" type="$2" action="${3:-check}" # check|create|validate
    local is_dir=$([ "$type" = "dir" ] && echo true || echo false)
    
    case "$action" in
        check)
            if [ "$is_dir" = true ]; then
                [ -d "$path" ]
            else
                [ -f "$path" ]
            fi
            ;;
        create)
            if [ "$is_dir" = true ]; then
                mkdir -p "$path"
            else
                mkdir -p "$(dirname "$path")" && touch "$path"
            fi
            ;;
        validate)
            if ! manage_path "$path" "$type" "check"; then
                log_error "$type not found at $path"
                return 1
            fi
            ;;
    esac
}

# Create item if missing
create_if_missing() {
    local item="$1" type="$2" base_path="$3"
    local full_path="$base_path/$item"
    local is_dir=$([ "$type" = "dir" ] && echo true || echo false)
    
    if ! path_exists "$full_path" "$is_dir"; then
        log_info "Creating missing $type: $full_path"
        if [ "$type" = "dir" ]; then
            mkdir -p "$full_path"
        else
            mkdir -p "$(dirname "$full_path")" && touch "$full_path"
        fi
    fi
}

#===============================================================================
# EXCLUDE PATTERN HANDLING (CONSOLIDATED)
#===============================================================================
# Get all exclude patterns as array
get_all_excludes() {
    local -a all_excludes=("${EXCLUDE_PATTERNS[@]}" "${EXTRA_EXCLUDES[@]}")
    printf '%s\n' "${all_excludes[@]}" | grep -v '^$' || true
}
# Build exclude arguments for different tools
build_excludes() {
    local tool="$1"
    local args="" pattern
    
    while IFS= read -r pattern; do
        [ -n "$pattern" ] || continue
        case "$tool" in
            diff)  args+=" -x $pattern" ;;
            rsync) args+=" --exclude=$pattern" ;;
        esac
    done < <(get_all_excludes)
    
    echo "$args"
}
# Remove ignored files under a directory
remove_ignored_files() {
    local base_dir="$1"
    
    while IFS= read -r pattern; do
        [ -n "$pattern" ] && find "$base_dir" -name "$pattern" -type f -delete 2>/dev/null || true
    done < <(get_all_excludes)
}

# Unified exclude handler
exclude_handler() {
    local action="$1" # args|clean
    local tool_or_dir="$2"
    
    case "$action" in
        args)
            build_excludes "$tool_or_dir"
            ;;
        clean)
            remove_ignored_files "$tool_or_dir"
            ;;
    esac
}
#===============================================================================
# ARGUMENT PARSING AND HELP
#===============================================================================
# Print usage
print_help() {
    cat <<EOF
Usage: sync-to-github.sh [options]
Options:
  -y, --yes, --non-interactive   Run without prompts; requires --prefer to decide conflicts
      --prefer <local|repo>      Choose source of truth when differences are found (default: repo)
      --branch <name>            Override target branch (default: $BRANCH)
      --exclude <pattern>        Add extra exclude pattern (can be repeated)
      --https                    Clone via HTTPS instead of SSH
  -h, --help                     Show this help

Description:
  Syncs CLAUDE.md file between \$HOME/.claude and the GitHub repository.
  In interactive mode, prompts for conflict resolution.
  In non-interactive mode, uses --prefer to automatically resolve conflicts.

Examples:
  $0 --yes --prefer repo
  $0 --prefer local
  bash <(curl -fsSL https://raw.githubusercontent.com/FradSer/dotclaude/main/sync-to-github.sh) --yes --prefer local
EOF
}
parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -y|--yes|--non-interactive) NON_INTERACTIVE=true ;;
            --prefer) PREFER_MODE="$2"; shift ;;
            --prefer=*) PREFER_MODE="${1#*=}" ;;
            --branch) TARGET_BRANCH="$2"; shift ;;
            --branch=*) TARGET_BRANCH="${1#*=}" ;;
            --exclude) EXTRA_EXCLUDES+=("$2"); shift ;;
            --exclude=*) EXTRA_EXCLUDES+=("${1#*=}") ;;
            --https) FORCE_HTTPS=true ;;
            -h|--help) print_help; exit 0 ;;
            *) log_warning "Unknown argument: $1" ;;
        esac
        shift
    done
}
#===============================================================================
# ENVIRONMENT DETECTION AND VALIDATION
#===============================================================================
# Check if directory is dotclaude project
is_dotclaude_project() {
    local check_dir="$1"
    [ -f "$check_dir/sync-to-github.sh" ] && [ -d "$check_dir/.git" ] && {
        local remote_url=$(cd "$check_dir" && git remote get-url origin 2>/dev/null || echo "")
        [[ "$remote_url" == *"dotclaude"* ]]
    }
}

# Unified execution context detection
detect_execution_context() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local current_dir="$(pwd)"

    # Guard clause: check if running locally in dotclaude project
    if is_dotclaude_project "$current_dir" && [ "$current_dir" = "$script_dir" ]; then
        echo "local $current_dir"
        return
    fi

    # Guard clause: check if script is from external dotclaude project
    if is_dotclaude_project "$script_dir" && [ "$current_dir" != "$script_dir" ]; then
        echo "external $script_dir"
        return
    fi

    # Default: remote execution
    echo "remote"
}
# Validate and create missing items - unified validation logic
validate_and_create_item() {
    local item="$1" type="$2" base_path="$3"
    local full_path="$base_path/$item"
    local is_dir=$([ "$type" = "dir" ] && echo true || echo false)

    if path_exists "$full_path" "$is_dir"; then
        return 0
    fi

    log_info "Creating missing $type: $full_path"
    if [ "$type" = "dir" ]; then
        mkdir -p "$full_path"
    else
        touch "$full_path"
    fi
}
# Validate Claude directory and required files
validate_environment() {
    log_info "Validating Claude environment..."

    # Ensure $HOME/.claude directory exists
    if [ ! -d "$HOME/.claude" ]; then
        log_info "Creating $HOME/.claude directory"
        mkdir -p "$HOME/.claude"
    fi

    # Create CLAUDE.md file if missing
    for item_spec in "${SYNC_ITEMS[@]}"; do
        local item="${item_spec%:*}" type="${item_spec#*:}"
        create_if_missing "$item" "$type" "$HOME/.claude"
    done

    log_info "All required files found or created at $HOME/.claude"
}
#===============================================================================
# FILE OPERATIONS AND DIFF HANDLING
#===============================================================================
# Show diff using best available tool
show_diff() {
    local file1="$1" file2="$2" is_dir="$3"
    local tool=$(get_diff_tool)
    local args=$([ "$is_dir" = true ] && echo "-ru" || echo "-u")
    
    echo -e "\n=== DIFF START ==="
    if [ "$is_dir" = true ]; then
        local exclude_args=$(exclude_handler "args" "diff")
        if command -v colordiff >/dev/null 2>&1; then
            # shellcheck disable=SC2086
            diff $args $exclude_args "$file1" "$file2" | colordiff || true
        else
            # shellcheck disable=SC2086
            diff $args $exclude_args "$file1" "$file2" || true
        fi
    else
        case $tool in
            colordiff) diff $args "$file1" "$file2" | colordiff || true ;;
            git) git diff --no-index --color=always "$file1" "$file2" || true ;;
            diff) diff $args "$file1" "$file2" || true ;;
        esac
    fi
    echo -e "=== DIFF END ===\n"
}
# Unified file operations
file_operation() {
    local op="$1" path1="$2" path2="${3:-}" is_dir="${4:-false}"
    
    case "$op" in
        copy)
            if [ "$is_dir" = true ]; then
                mkdir -p "$path2"
                if command -v rsync >/dev/null 2>&1; then
                    local exclude_args=$(exclude_handler "args" "rsync")
                    # shellcheck disable=SC2086
                    rsync -a $exclude_args "$path1"/ "$path2"/
                else
                    cp -r "$path1"/* "$path2"/ 2>/dev/null || true
                    exclude_handler "clean" "$path2"
                fi
            else
                mkdir -p "$(dirname "$path2")"
                cp "$path1" "$path2"
            fi
            ;;
        remove)
            [ "$is_dir" = true ] && rm -rf "$path1" || rm -f "$path1"
            ;;
        compare)
            if [ "$is_dir" = true ]; then
                local exclude_args=$(exclude_handler "args" "diff")
                # shellcheck disable=SC2086
                diff -r $exclude_args "$path1" "$path2" &>/dev/null
            else
                cmp -s "$path1" "$path2" &>/dev/null
            fi
            ;;
    esac
}

#===============================================================================
# UNIFIED MENU SYSTEM
#===============================================================================
# Get menu configuration for scenario
get_menu_config() {
    local scenario="$1"
    case "$scenario" in
        diff) echo "1:Use local %s (overwrite repo)|2:Use repo %s (overwrite local)|3:Skip this %s|4:Show detailed diff" ;;
        local_only) echo "1:Copy to repo|2:Delete local %s|3:Skip" ;;
        repo_only) echo "1:Copy to local|2:Delete from repo|3:Skip" ;;
    esac
}

# Get auto choice for non-interactive mode
get_auto_choice() {
    local scenario="$1" prefer_mode="$2"
    case "${scenario}_${prefer_mode}" in
        diff_local|local_only_local|repo_only_repo) echo "$MENU_CHOICE_USE_LOCAL" ;;
        diff_repo|local_only_repo|repo_only_local) echo "$MENU_CHOICE_USE_REPO" ;;
        *) echo "$MENU_CHOICE_SKIP" ;;
    esac
}
# Unified menu display and choice handling
show_menu_and_get_choice() {
    local scenario="$1" item="$2" prefer_mode="${3:-repo}"
    
    if [ "$NON_INTERACTIVE" = true ]; then
        get_auto_choice "$scenario" "$prefer_mode"
        return
    fi
    
    local menu_config=$(get_menu_config "$scenario")
    echo "Choose action:"
    
    local IFS='|'
    for option in $menu_config; do
        printf "$option\n" "$item"
    done
    
    local max_choices=$(echo "$menu_config" | tr '|' '\n' | wc -l | tr -d ' ')
    read -p "Enter choice (1-$max_choices): " choice
    echo "$choice"
}
# Get action for scenario and choice
get_action() {
    local scenario="$1" choice="$2"
    case "${scenario}_${choice}" in
        diff_${MENU_CHOICE_USE_LOCAL}) echo "use_local" ;;
        diff_${MENU_CHOICE_USE_REPO}) echo "use_repo" ;;
        diff_${MENU_CHOICE_SHOW_DIFF}) echo "show_diff" ;;
        local_only_${MENU_CHOICE_USE_LOCAL}) echo "copy_to_repo" ;;
        local_only_${MENU_CHOICE_USE_REPO}) echo "delete_local" ;;
        repo_only_${MENU_CHOICE_USE_LOCAL}) echo "copy_to_local" ;;
        repo_only_${MENU_CHOICE_USE_REPO}) echo "delete_repo" ;;
        *) echo "" ;;
    esac
}
# Execute action based on choice
execute_action() {
    local scenario="$1" choice="$2" local_path="$3" repo_path="$4" item="$5" is_dir="$6"

    [ "$choice" = "$MENU_CHOICE_SKIP" ] && { log_info "Skipping $item"; return "$STATUS_NO_CHANGES"; }

    local action=$(get_action "$scenario" "$choice")

    case "$action" in
        use_local)
            log_info "Using local $item"
            [ "$is_dir" = true ] && file_operation "remove" "$repo_path" "" "$is_dir"
            file_operation "copy" "$local_path" "$repo_path" "$is_dir"
            return "$STATUS_CHANGES_MADE"
            ;;
        use_repo)
            log_info "Using repo $item"
            [ "$is_dir" = true ] && file_operation "remove" "$local_path" "" "$is_dir"
            file_operation "copy" "$repo_path" "$local_path" "$is_dir"
            return "$STATUS_CHANGES_MADE"
            ;;
        copy_to_repo)
            log_info "Copying to repo"
            file_operation "copy" "$local_path" "$repo_path" "$is_dir"
            return "$STATUS_CHANGES_MADE"
            ;;
        delete_local)
            log_info "Deleting local $item"
            file_operation "remove" "$local_path" "" "$is_dir"
            return "$STATUS_CHANGES_MADE"
            ;;
        copy_to_local)
            log_info "Copying to local"
            file_operation "copy" "$repo_path" "$local_path" "$is_dir"
            return "$STATUS_CHANGES_MADE"
            ;;
        delete_repo)
            log_info "Deleting from repo"
            file_operation "remove" "$repo_path" "" "$is_dir"
            return "$STATUS_CHANGES_MADE"
            ;;
        show_diff)
            return "$STATUS_NO_CHANGES"  # Diff handling in calling function
            ;;
        *)
            log_error "Invalid choice, skipping $item"
            return "$STATUS_NO_CHANGES"
            ;;
    esac
}
#===============================================================================
# SYNC SCENARIO HANDLING
#===============================================================================
# Unified sync handler for all scenarios
sync_handler() {
    local local_path="$1" repo_path="$2" item="$3" is_dir="$4" scenario="$5"
    
    case "$scenario" in
        both_exist)
            if file_operation "compare" "$local_path" "$repo_path" "$is_dir"; then
                log_info "$item: Items are identical, skipping"
                return 0
            fi
            log_warning "$item: Items are different"
            printf "Local: %s\nRepo: %s\n\n" "$local_path" "$repo_path"
            scenario="diff"
            ;;
        local_only)
            log_warning "$item: Only exists locally"
            ;;
        repo_only)
            log_warning "$item: Only exists in repo"
            ;;
    esac
    
    local choice=$(show_menu_and_get_choice "$scenario" "$item" "$PREFER_MODE")
    
    # Handle diff display for interactive mode
    if [ "$scenario" = "diff" ] && [ "$choice" = "$MENU_CHOICE_SHOW_DIFF" ] && [ "$NON_INTERACTIVE" != true ]; then
        show_diff "$local_path" "$repo_path" "$is_dir"
        choice=$(show_menu_and_get_choice "$scenario" "$item" "$PREFER_MODE")
    fi
    
    execute_action "$scenario" "$choice" "$local_path" "$repo_path" "$item" "$is_dir"
}
# Compare items and determine sync scenario
compare_items() {
    local local_path="$1" repo_path="$2" item="$3" is_dir="$4"
    local path_type=$([ "$is_dir" = true ] && echo dir || echo file)
    local local_exists=$(manage_path "$local_path" "$path_type" "check" && echo true || echo false)
    local repo_exists=$(manage_path "$repo_path" "$path_type" "check" && echo true || echo false)
    
    case "${local_exists}_${repo_exists}" in
        true_true)   sync_handler "$local_path" "$repo_path" "$item" "$is_dir" "both_exist" ;;
        true_false)  sync_handler "$local_path" "$repo_path" "$item" "$is_dir" "local_only" ;;
        false_true)  sync_handler "$local_path" "$repo_path" "$item" "$is_dir" "repo_only" ;;
        false_false) log_warning "$item: Does not exist in either location"; return 0 ;;
    esac
}
#===============================================================================
# GIT OPERATIONS
#===============================================================================
# Git utility functions - consolidated and simplified
clone_repo() {
    local repo_url="$1" target_dir="$2"
    [ -d "$target_dir" ] && rm -rf "$target_dir"
    git clone "$repo_url" "$target_dir"
}
checkout_branch() {
    local branch="$1"
    git checkout "$branch" || { log_error "Failed to checkout branch $branch"; exit 1; }
}

# Setup git repository based on execution context
setup_repo() {
    local context=$(detect_execution_context)
    local context_type="${context%% *}"
    local context_dir="${context#* }"
    
    case "$context_type" in
        local)
            log_info "Running in local dotclaude project mode"
            WORKING_DIR="$(pwd)"
            ;;
        external)
            log_info "Running external script from dotclaude project directory"
            WORKING_DIR="$context_dir"
            cd "$WORKING_DIR" || { log_error "Failed to change to script directory"; exit 1; }
            ;;
        remote)
            log_info "Setting up git repository"
            local repo_url=$([ "$FORCE_HTTPS" = true ] && echo "$REPO_URL_HTTPS" || echo "$REPO_URL")
            
            if ! clone_repo "$repo_url" "$TEMP_DIR"; then
                if [ "$FORCE_HTTPS" != true ]; then
                    log_warning "SSH clone failed, falling back to HTTPS"
                    clone_repo "$REPO_URL_HTTPS" "$TEMP_DIR" || { log_error "Failed to clone repository"; exit 1; }
                else
                    log_error "Failed to clone repository"; exit 1
                fi
            fi
            
            cd "$TEMP_DIR" || { log_error "Failed to change to temp directory"; exit 1; }
            checkout_branch "$TARGET_BRANCH"
            WORKING_DIR="$TEMP_DIR"
            ;;
    esac
    
    log_info "Using working directory: $WORKING_DIR"
}

# Cleanup temporary directory
cleanup() {
    local context=$(detect_execution_context)
    local context_type="${context%% *}"
    
    # Only cleanup temp directory if we cloned a repo (remote mode)
    if [ "$context_type" = "remote" ] && [ -d "$TEMP_DIR" ]; then
        log_info "Cleaning up temp directory"
        rm -rf "$TEMP_DIR"
    fi
}
#===============================================================================
# MAIN SYNC AND EXECUTION
#===============================================================================
# Compare and sync items between $HOME/.claude and repository
sync_items() {
    log_info "Comparing and syncing items..."
    local has_changes=false
    
    # Change to working directory for sync operations
    cd "$WORKING_DIR"
    
    for item_spec in "${SYNC_ITEMS[@]}"; do
        local item="${item_spec%:*}"
        local type="${item_spec#*:}"
        local is_dir=$([ "$type" = "dir" ] && echo true || echo false)
        
        # REQUIREMENT: Always compare $HOME/.claude content with repository
        local home_claude_path="$HOME/.claude/$item"
        local repo_item_path="$item"
        
        if ! compare_home_claude_content "$home_claude_path" "$repo_item_path" "$item" "$is_dir"; then
            has_changes=true
        fi
    done
    
    [ "$has_changes" = true ] && log_info "Files synced with user choices" || log_info "No changes needed"
}
# Check if items exist and return existence status
check_existence_scenario() {
    local claude_path="$1" repo_path="$2" is_dir="$3"
    local path_type=$([ "$is_dir" = true ] && echo "dir" || echo "file")
    local claude_exists repo_exists

    claude_exists=$(manage_path "$claude_path" "$path_type" "check" && echo true || echo false)
    repo_exists=$(manage_path "$repo_path" "$path_type" "check" && echo true || echo false)

    echo "${claude_exists}_${repo_exists}"
}

# Handle sync when item exists in only one location
handle_one_sided_sync() {
    local claude_path="$1" repo_path="$2" item="$3" is_dir="$4" scenario="$5"

    case "$scenario" in
        true_false)
            log_info "$item: Only exists in $HOME/.claude, copying to repository"
            file_operation "copy" "$claude_path" "$repo_path" "$is_dir"
            return "$STATUS_CHANGES_MADE"
            ;;
        false_true)
            log_info "$item: Only exists in repository, copying to $HOME/.claude"
            file_operation "copy" "$repo_path" "$claude_path" "$is_dir"
            return "$STATUS_CHANGES_MADE"
            ;;
    esac
}

# Handle interactive resolution of content differences
handle_interactive_diff_resolution() {
    local claude_path="$1" repo_path="$2" item="$3" is_dir="$4"

    log_warning "$item: Content differs between $HOME/.claude and repository"
    printf "  $HOME/.claude: %s\n" "$claude_path"
    printf "  Repository: %s\n\n" "$repo_path"

    echo "Choose action:"
    echo "1) Use $HOME/.claude version (overwrite repository)"
    echo "2) Use repository version (overwrite $HOME/.claude)"
    echo "3) Skip this item"
    echo "4) Show detailed diff"

    while true; do
        read -p "Enter choice (1-4): " choice

        case "$choice" in
            "$MENU_CHOICE_USE_LOCAL")
                log_info "Using $HOME/.claude version for $item"
                [ "$is_dir" = true ] && file_operation "remove" "$repo_path" "" "$is_dir"
                file_operation "copy" "$claude_path" "$repo_path" "$is_dir"
                return "$STATUS_CHANGES_MADE"
                ;;
            "$MENU_CHOICE_USE_REPO")
                log_info "Using repository version for $item"
                [ "$is_dir" = true ] && file_operation "remove" "$claude_path" "" "$is_dir"
                file_operation "copy" "$repo_path" "$claude_path" "$is_dir"
                return "$STATUS_CHANGES_MADE"
                ;;
            "$MENU_CHOICE_SKIP")
                log_info "Skipping $item"
                return "$STATUS_NO_CHANGES"
                ;;
            "$MENU_CHOICE_SHOW_DIFF")
                show_diff "$claude_path" "$repo_path" "$is_dir"
                echo "Choose action:"
                echo "1) Use $HOME/.claude version (overwrite repository)"
                echo "2) Use repository version (overwrite $HOME/.claude)"
                echo "3) Skip this item"
                ;;
            *)
                echo "Invalid choice. Please enter 1, 2, 3, or 4."
                ;;
        esac
    done
}

# Special handling for $HOME/.claude content comparison
compare_home_claude_content() {
    local claude_path="$1" repo_path="$2" item="$3" is_dir="$4"
    local existence_scenario

    existence_scenario=$(check_existence_scenario "$claude_path" "$repo_path" "$is_dir")

    # Guard clause: skip if neither exists
    if [ "$existence_scenario" = "false_false" ]; then
        log_warning "$item: Does not exist in either location"
        return 0
    fi

    # Handle one-sided existence
    if [[ "$existence_scenario" =~ ^(true_false|false_true)$ ]]; then
        handle_one_sided_sync "$claude_path" "$repo_path" "$item" "$is_dir" "$existence_scenario"
        return $?
    fi

    # Both exist - check if identical
    if file_operation "compare" "$claude_path" "$repo_path" "$is_dir"; then
        log_info "$item: Content is identical between $HOME/.claude and repository"
        return 0
    fi

    # Content differs - handle interactively
    handle_interactive_diff_resolution "$claude_path" "$repo_path" "$item" "$is_dir"
}
# Main execution flow
main() {
    parse_args "$@"

    log_info "Starting CLAUDE.md sync process"
    validate_environment
    log_info "Using diff tool: $(get_diff_tool)"
    setup_repo

    sync_items
    cleanup

    echo -e "${GREEN}Sync completed successfully!${NC}"
}
# Handle script interruption
trap cleanup EXIT
# Run main function
main "$@"