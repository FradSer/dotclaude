#!/bin/bash

# Sync script for dotclaude repository
# Syncs agents folder and CLAUDE.md to https://github.com/FradSer/dotclaude

set -e

#===============================================================================
# CONFIGURATION AND CONSTANTS
#===============================================================================

# Repository configuration
readonly REPO_URL="git@github.com:FradSer/dotclaude.git"
readonly REPO_URL_HTTPS="https://github.com/FradSer/dotclaude.git"
readonly TEMP_DIR="/tmp/dotclaude-sync"
readonly BRANCH="main"
readonly CLAUDE_DIR="$HOME/.claude"
readonly ITEMS=("agents:dir" "commands:dir" "CLAUDE.md:file")
readonly EXCLUDE_PATTERNS=(".DS_Store")

# Colors for output
readonly RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NC='\033[0m'

# Runtime options (overridable by CLI flags)
NON_INTERACTIVE=false
PREFER_MODE="repo"       # valid: local | repo; default: repo
AUTO_COMMIT=false        # if true in non-interactive mode, auto-commit
AUTO_PUSH=false          # if true in non-interactive mode and AUTO_COMMIT=true, also push
SKIP_COMMIT=false        # force skip commit even if changes exist
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

# Parse item specification (name:type format)
parse_item_spec() {
    local item_spec="$1"
    echo "${item_spec%:*}" "${item_spec#*:}"
}

# Check if path exists based on type
path_exists() {
    local path="$1" is_dir="$2"
    local test_flag=$([ "$is_dir" = true ] && echo "-d" || echo "-f")
    [ $test_flag "$path" ]
}

#===============================================================================
# EXCLUDE PATTERN HANDLING (CONSOLIDATED)
#===============================================================================

# Build exclude arguments for diff command
build_diff_excludes() {
    local args=""
    local pattern
    for pattern in "${EXCLUDE_PATTERNS[@]}" "${EXTRA_EXCLUDES[@]}"; do
        [ -n "$pattern" ] && args+=" -x $pattern"
    done
    echo "$args"
}

# Build exclude arguments for rsync command
build_rsync_excludes() {
    local args=""
    local pattern
    for pattern in "${EXCLUDE_PATTERNS[@]}" "${EXTRA_EXCLUDES[@]}"; do
        [ -n "$pattern" ] && args+=" --exclude=$pattern"
    done
    echo "$args"
}

# Remove ignored files under a directory
remove_ignored_files() {
    local base_dir="$1"
    local pattern
    for pattern in "${EXCLUDE_PATTERNS[@]}" "${EXTRA_EXCLUDES[@]}"; do
        [ -n "$pattern" ] && find "$base_dir" -name "$pattern" -type f -delete 2>/dev/null || true
    done
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
      --commit                   In non-interactive mode: commit changes automatically
      --push                     In non-interactive mode: push after commit (implies --commit)
      --no-commit                In non-interactive mode: skip commit even if changes exist
      --branch <name>            Override target branch (default: $BRANCH)
      --exclude <pattern>        Add extra exclude pattern (can be repeated)
      --https                    Clone via HTTPS instead of SSH
  -h, --help                     Show this help

Examples:
  ./sync-to-github.sh --yes --prefer repo --commit --push
  bash <(curl -fsSL https://raw.githubusercontent.com/FradSer/dotclaude/main/sync-to-github.sh) --yes --prefer local
EOF
}

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -y|--yes|--non-interactive) NON_INTERACTIVE=true ;;
            --prefer) PREFER_MODE="$2"; shift ;;
            --prefer=*) PREFER_MODE="${1#*=}" ;;
            --commit) AUTO_COMMIT=true ;;
            --push) AUTO_COMMIT=true; AUTO_PUSH=true ;;
            --no-commit) SKIP_COMMIT=true; AUTO_COMMIT=false ;;
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

# Detect if we're running within the dotclaude project
detect_local_mode() {
    if [ -f "$(pwd)/sync-to-github.sh" ] && [ -d "$(pwd)/.git" ]; then
        local remote_url
        remote_url=$(git remote get-url origin 2>/dev/null || echo "")
        if [[ "$remote_url" == *"dotclaude"* ]]; then
            echo "true"
            return
        fi
    fi
    echo "false"
}

validate_directory_exists() {
    local dir="$1" description="$2"
    [ ! -d "$dir" ] && log_error "$description not found at $dir" && exit 1
    log_info "Found $description at $dir"
}

validate_item_exists() {
    local item="$1" type="$2" base_dir="$3"
    local path="$base_dir/$item"
    local test_flag=$([ "$type" = "dir" ] && echo "-d" || echo "-f")
    
    if [ ! $test_flag "$path" ]; then
        log_error "$item $type not found at $path"
        return 1
    fi
    return 0
}

# Validate Claude directory and required files
validate_environment() {
    log_info "Validating Claude environment..."
    validate_directory_exists "$CLAUDE_DIR" "Claude directory"
    
    local missing_items=()
    for item_spec in "${ITEMS[@]}"; do
        local item="${item_spec%:*}" type="${item_spec#*:}"
        if ! validate_item_exists "$item" "$type" "$CLAUDE_DIR"; then
            missing_items+=("$item")
        fi
    done
    
    if [ ${#missing_items[@]} -gt 0 ]; then
        log_error "Missing required items. Creating them..."
        for item in "${missing_items[@]}"; do
            local item_spec type path
            for spec in "${ITEMS[@]}"; do
                if [[ "$spec" == "$item:"* ]]; then
                    item_spec="$spec"
                    break
                fi
            done
            type="${item_spec#*:}"
            path="$CLAUDE_DIR/$item"
            
            if [ "$type" = "dir" ]; then
                mkdir -p "$path"
                log_info "Created directory: $path"
            else
                touch "$path"
                log_info "Created file: $path"
            fi
        done
    fi
    
    log_info "All required files found or created"
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
        local exclude_args
        exclude_args=$(build_diff_excludes)
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

# Copy path with proper handling for directories and files
copy_path() {
    local src="$1" dest="$2" is_dir="$3"
    if [ "$is_dir" = true ]; then
        if command -v rsync >/dev/null 2>&1; then
            local exclude_args
            exclude_args=$(build_rsync_excludes)
            mkdir -p "$dest"
            # shellcheck disable=SC2086
            rsync -a $exclude_args "$src"/ "$dest"/
        else
            cp -r "$src" "$dest"
            remove_ignored_files "$dest" || true
        fi
    else
        cp "$src" "$dest"
    fi
}

# Remove path (file or directory)
remove_path() {
    local path="$1" is_dir="$2"
    [ "$is_dir" = true ] && rm -rf "$path" || rm -f "$path"
}

# Check if two paths have identical content
paths_identical() {
    local path1="$1" path2="$2" is_dir="$3"
    if [ "$is_dir" = true ]; then
        local exclude_args
        exclude_args=$(build_diff_excludes)
        # shellcheck disable=SC2086
        diff -r $exclude_args "$path1" "$path2" &>/dev/null
    else
        cmp -s "$path1" "$path2" &>/dev/null
    fi
}

#===============================================================================
# MENU SYSTEM AND CHOICE HANDLING
#===============================================================================

# Menu configurations
get_menu_config() {
    local scenario="$1"
    case "$scenario" in
        diff)
            echo "Use local %s (overwrite repo)|Use repo %s (overwrite local)|Skip this %s|Show detailed diff" "Enter choice (1-4): "
            ;;
        local_only)
            echo "Copy to repo|Delete local %s|Skip" "Enter choice (1-3): "
            ;;
        repo_only)
            echo "Copy to local|Delete from repo|Skip" "Enter choice (1-3): "
            ;;
    esac
}

# Display formatted menu options
display_menu() {
    local scenario="$1" item="$2"
    local menu_data prompt counter=1 option
    
    menu_data=$(get_menu_config "$scenario")
    local options="${menu_data% *}"
    prompt="${menu_data##* }"
    
    echo "Choose action:"
    local old_ifs="$IFS"; IFS='|'
    for option in $options; do
        printf "%d) %s\n" "$counter" "$(printf "$option" "$item")"
        ((counter++))
    done
    IFS="$old_ifs"
    
    read -p "$prompt"
}

# Get non-interactive choice based on preference mode
get_auto_choice() {
    local scenario="$1" prefer_mode="$2"
    
    case "${scenario}_${prefer_mode}" in
        diff_local|local_only_local|repo_only_repo) echo "1" ;;
        diff_repo|local_only_repo|repo_only_local) echo "2" ;;
        *) echo "3" ;;
    esac
}

# Execute file operations based on choice - returns 1 if changes made, 0 if skipped
execute_choice() {
    local choice="$1" scenario="$2" local_path="$3" repo_path="$4" item="$5" is_dir="$6"
    
    case "${scenario}_${choice}" in
        diff_1|local_only_1)
            log_info "Using/copying local $item"
            [ "$is_dir" = true ] && [ "$scenario" = "diff" ] && rm -rf "$repo_path"
            copy_path "$local_path" "$repo_path" "$is_dir"
            return 1
            ;;
        diff_2|repo_only_1)
            log_info "Using/copying repo $item"
            [ "$is_dir" = true ] && [ "$scenario" = "diff" ] && rm -rf "$local_path"
            copy_path "$repo_path" "$local_path" "$is_dir"
            return 1
            ;;
        local_only_2)
            log_info "Deleting local $item"
            remove_path "$local_path" "$is_dir"
            return 1
            ;;
        repo_only_2)
            log_info "Deleting $item from repo"
            remove_path "$repo_path" "$is_dir"
            return 1
            ;;
        *_3)
            log_info "Skipping $item"
            return 0
            ;;
        *)
            log_error "Invalid choice, skipping $item"
            return 0
            ;;
    esac
}

#===============================================================================
# SYNC SCENARIO HANDLING
#===============================================================================

# Handle scenario where both local and repo items exist
handle_both_exist() {
    local local_path="$1" repo_path="$2" item="$3" is_dir="$4"
    
    if paths_identical "$local_path" "$repo_path" "$is_dir"; then
        log_info "$item: Items are identical, skipping"
        return 0
    fi
    
    log_warning "$item: Items are different"
    printf "Local: %s\nRepo: %s\n\n" "$local_path" "$repo_path"
    
    local choice
    if [ "$NON_INTERACTIVE" = true ]; then
        choice=$(get_auto_choice "diff" "$PREFER_MODE")
    else
        display_menu "diff" "$item"
        choice="$REPLY"
        if [ "$choice" = "4" ]; then
            show_diff "$local_path" "$repo_path" "$is_dir"
            display_menu "diff" "$item"
            choice="$REPLY"
        fi
    fi
    
    if [[ "$choice" =~ ^[1-3]$ ]]; then
        execute_choice "$choice" "diff" "$local_path" "$repo_path" "$item" "$is_dir"
    else
        return 0
    fi
}

# Handle scenario where only one location has the item
handle_single_location() {
    local local_path="$1" repo_path="$2" item="$3" is_dir="$4" scenario="$5"
    
    log_warning "$item: Only exists $([[ "$scenario" == "local_only" ]] && echo "locally" || echo "in repo")"
    
    local choice
    if [ "$NON_INTERACTIVE" = true ]; then
        choice=$(get_auto_choice "$scenario" "$PREFER_MODE")
    else
        display_menu "$scenario" "$item"
        choice="$REPLY"
    fi
    
    execute_choice "$choice" "$scenario" "$local_path" "$repo_path" "$item" "$is_dir"
}

# Compare items and handle sync decisions
compare_items() {
    local local_path="$1" repo_path="$2" item="$3" is_dir="$4"
    local local_exists repo_exists
    
    local_exists=$(path_exists "$local_path" "$is_dir" && echo true || echo false)
    repo_exists=$(path_exists "$repo_path" "$is_dir" && echo true || echo false)
    
    case "${local_exists}_${repo_exists}" in
        true_true)   handle_both_exist "$local_path" "$repo_path" "$item" "$is_dir" ;;
        true_false)  handle_single_location "$local_path" "$repo_path" "$item" "$is_dir" "local_only" ;;
        false_true)  handle_single_location "$local_path" "$repo_path" "$item" "$is_dir" "repo_only" ;;
        false_false) log_warning "$item: Does not exist in either location"; return 0 ;;
    esac
}

#===============================================================================
# GIT OPERATIONS
#===============================================================================

# Git utility functions
clone_repo() {
    local repo_url="$1" target_dir="$2"
    [ -d "$target_dir" ] && rm -rf "$target_dir"
    git clone "$repo_url" "$target_dir" || return 1
}

checkout_branch() {
    local branch="$1"
    git checkout "$branch" || { log_error "Failed to checkout branch $branch"; exit 1; }
}

has_git_changes() {
    ! (git diff --quiet && git diff --cached --quiet)
}

show_git_status() {
    git status --porcelain
}

stage_all_changes() {
    git add . || { log_error "Failed to stage changes"; return 1; }
}

commit_changes() {
    local commit_msg="$1"
    git commit -m "$commit_msg" || { log_error "Failed to commit changes"; return 1; }
}

push_changes() {
    local branch="$1"
    git push origin "$branch" || { log_error "Failed to push changes"; return 1; }
}

# Check for specific file changes in git status
check_file_changes() {
    local pattern="$1"
    show_git_status | grep -q "$pattern"
}

# Generate commit message
generate_commit_message() {
    local changes_summary
    changes_summary=$(show_git_status | head -10)
    
    if command -v claude >/dev/null 2>&1; then
        log_info "Using Claude to generate commit message..."
        local claude_msg
        claude_msg=$(claude --no-color <<EOF | tail -1
Generate a conventional commit message for these changes:
$changes_summary

Requirements:
- Start with feat:, fix:, docs:, style:, refactor:, test:, or chore:
- Be concise and descriptive
- No timestamp needed
- Focus on what was changed, not how
- Return only the commit message, no explanation
EOF
)
        [ -n "$claude_msg" ] && echo "$claude_msg" || generate_fallback_message
    else
        log_info "Claude not available, using conventional commit format..."
        generate_fallback_message
    fi
}

# Generate fallback commit message based on changed items
generate_fallback_message() {
    local changed_items=""
    local -a patterns=("agents/" "commands/" "CLAUDE.md")
    local -a labels=("agents" "commands" "config")
    
    for i in "${!patterns[@]}"; do
        check_file_changes "${patterns[$i]}" && changed_items+="${labels[$i]} "
    done
    
    printf "feat: sync dotclaude %supdates" "${changed_items:-configuration }"
}

# Detect if we're running within the dotclaude project
detect_local_mode() {
    if [ -f "$(pwd)/sync-to-github.sh" ] && [ -d "$(pwd)/.git" ]; then
        local remote_url
        remote_url=$(git remote get-url origin 2>/dev/null || echo "")
        if [[ "$remote_url" == *"dotclaude"* ]]; then
            echo "true"
            return
        fi
    fi
    echo "false"
}

# Setup git repository
setup_repo() {
    local LOCAL_MODE
    LOCAL_MODE=$(detect_local_mode)
    
    if [ "$LOCAL_MODE" = "true" ]; then
        log_info "Running in local dotclaude project mode..."
        WORKING_DIR="$(pwd)"
        log_info "Using current directory: $WORKING_DIR"
    else
        log_info "Setting up git repository..."
        
        local chosen_url
        if [ "$FORCE_HTTPS" = true ]; then
            chosen_url="$REPO_URL_HTTPS"
        else
            chosen_url="$REPO_URL"
        fi

        if ! clone_repo "$chosen_url" "$TEMP_DIR"; then
            if [ "$FORCE_HTTPS" != true ]; then
                log_warning "SSH clone failed, falling back to HTTPS..."
                clone_repo "$REPO_URL_HTTPS" "$TEMP_DIR" || { log_error "Failed to clone repository"; exit 1; }
            else
                log_error "Failed to clone repository"; exit 1
            fi
        fi
        cd "$TEMP_DIR" || { log_error "Failed to change to temp directory"; exit 1; }
        checkout_branch "$TARGET_BRANCH"
        WORKING_DIR="$TEMP_DIR"
        
        log_info "Repository setup completed"
    fi
}

# Commit and push changes if any exist
commit_and_push() {
    log_info "Checking for changes to commit..."
    
    if ! has_git_changes; then
        log_info "No changes to commit"
        return
    fi
    
    log_info "Changes to be committed:"
    show_git_status
    
    if [ "$NON_INTERACTIVE" = true ]; then
        if [ "$SKIP_COMMIT" = true ]; then
            log_warning "Skipping commit (non-interactive mode)"
            return
        fi
        if [ "$AUTO_COMMIT" = true ]; then
            log_info "Committing changes (non-interactive mode)..."
            stage_all_changes || return 1
            local commit_msg
            commit_msg=$(generate_commit_message)
            commit_changes "$commit_msg" || return 1
            if [ "$AUTO_PUSH" = true ]; then
                push_changes "$TARGET_BRANCH" || return 1
                echo -e "${GREEN}Changes committed and pushed successfully${NC}"
            else
                echo -e "${GREEN}Changes committed successfully (no push)${NC}"
            fi
        else
            log_warning "Changes detected but --commit not set; skipping commit"
        fi
        return
    fi
    
    echo -e "\nChoose action:\n1) Commit and push changes\n2) Skip commit"
    read -p "Enter choice (1-2): " choice
    case $choice in
        1)
            log_info "Committing and pushing changes..."
            stage_all_changes || return 1
            local commit_msg
            commit_msg=$(generate_commit_message)
            commit_changes "$commit_msg" || return 1
            push_changes "$TARGET_BRANCH" || return 1
            echo -e "${GREEN}Changes committed and pushed successfully${NC}"
            ;;
        2) log_warning "Skipping commit" ;;
        *) log_error "Invalid choice, skipping commit" ;;
    esac
}

# Cleanup temporary directory
cleanup() {
    local LOCAL_MODE
    LOCAL_MODE=$(detect_local_mode)
    if [ "$LOCAL_MODE" != "true" ] && [ -d "$TEMP_DIR" ]; then
        log_info "Cleaning up..." 
        rm -rf "$TEMP_DIR"
    fi
}

#===============================================================================
# MAIN SYNC AND EXECUTION
#===============================================================================

# Sync all items with user interaction
sync_items() {
    log_info "Comparing and syncing items..."
    local has_changes=false
    
    # Change to working directory for sync operations
    cd "$WORKING_DIR"
    
    for item_spec in "${ITEMS[@]}"; do
        local item="${item_spec%:*}"
        local type="${item_spec#*:}"
        local is_dir=$([ "$type" = "dir" ] && echo true || echo false)
        
        if ! compare_items "$CLAUDE_DIR/$item" "$item" "$item" "$is_dir"; then
            has_changes=true
        fi
    done
    
    [ "$has_changes" = true ] && log_info "Files synced with user choices" || log_info "No changes needed"
}

# Main execution flow
main() {
    log_info "Starting sync process for Claude directory: $CLAUDE_DIR"
    parse_args "$@"
    
    validate_environment
    log_info "Using diff tool: $(get_diff_tool)"
    setup_repo
    sync_items
    commit_and_push
    cleanup
    
    echo -e "${GREEN}Sync completed successfully!${NC}"
}

# Handle script interruption
trap cleanup EXIT

# Run main function
main "$@"