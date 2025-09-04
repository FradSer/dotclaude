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
# CLAUDE_DIR will be set dynamically based on execution context
CLAUDE_DIR=""
# Items for sync operations
readonly SYNC_ITEMS=("agents:dir" "commands:dir" "CLAUDE.md:file")
# Items for project-local .claude directory (only agents, no commands or CLAUDE.md)
readonly CLAUDE_DIR_ITEMS=("agents:dir")
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
COPY_LOCAL_AGENT=""      # specific local agent to copy to .claude/agents
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

#===============================================================================
# LOCAL AGENTS MANAGEMENT
#===============================================================================

# List available agents in local-agents directory
list_local_agents() {
    local local_agents_dir="$(pwd)/local-agents"
    
    if [ ! -d "$local_agents_dir" ]; then
        log_error "local-agents directory not found at $local_agents_dir"
        return 1
    fi
    
    log_info "Available agents in local-agents/:"
    if [ -z "$(ls -A "$local_agents_dir" 2>/dev/null)" ]; then
        echo "  (no agents found)"
        return 0
    fi
    
    for agent in "$local_agents_dir"/*.md; do
        [ -f "$agent" ] && echo "  $(basename "$agent")"
    done
}

# Interactive agent selection menu
select_local_agent() {
    local local_agents_dir="$(pwd)/local-agents"
    
    if [ ! -d "$local_agents_dir" ]; then
        log_error "local-agents directory not found at $local_agents_dir"
        return 1
    fi
    
    # Collect available agents into an array
    local agents=()
    for agent in "$local_agents_dir"/*.md; do
        [ -f "$agent" ] && agents+=("$(basename "$agent")")
    done
    
    # Check if any agents found
    if [ ${#agents[@]} -eq 0 ]; then
        log_error "No agents found in local-agents/"
        return 1
    fi
    
    # Display agent selection menu
    echo "Available agents in local-agents/:"
    for i in "${!agents[@]}"; do
        printf "%d) %s\n" $((i+1)) "${agents[$i]}"
    done
    echo "$((${#agents[@]}+1))) Cancel"
    
    # Get user choice
    while true; do
        read -p "Select agent to copy (1-$((${#agents[@]}+1))): " choice
        
        # Validate choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $((${#agents[@]}+1)) ]; then
            if [ "$choice" -eq $((${#agents[@]}+1)) ]; then
                log_info "Agent copy cancelled"
                return 0
            else
                # Return selected agent name
                echo "${agents[$((choice-1))]}"
                return 0
            fi
        else
            echo "Invalid choice. Please enter a number between 1 and $((${#agents[@]}+1))."
        fi
    done
}

# Copy specific agent from local-agents to .claude/agents
copy_local_agent() {
    local agent_name="$1"
    local local_agents_dir="$(pwd)/local-agents"
    local claude_agents_dir="$CLAUDE_DIR/agents"
    
    # If no agent name provided, show interactive selection
    if [ -z "$agent_name" ]; then
        log_info "No agent specified. Please select from available agents:"
        agent_name=$(select_local_agent)
        
        # Check if selection was cancelled or failed
        if [ $? -ne 0 ] || [ -z "$agent_name" ]; then
            return 1
        fi
    fi
    
    local source_file="$local_agents_dir/$agent_name"
    local dest_file="$claude_agents_dir/$agent_name"
    
    # Validate source exists
    if [ ! -f "$source_file" ]; then
        log_error "Agent '$agent_name' not found in local-agents/"
        log_info "Available agents:"
        list_local_agents
        return 1
    fi
    
    # Ensure destination directory exists
    mkdir -p "$claude_agents_dir"
    
    # Check if destination already exists and prompt if different
    if [ -f "$dest_file" ]; then
        if cmp -s "$source_file" "$dest_file"; then
            log_info "Agent '$agent_name' is already up to date in $claude_agents_dir"
            return 0
        else
            log_warning "Agent '$agent_name' already exists in $claude_agents_dir but differs from local version"
            if [ "$NON_INTERACTIVE" != true ]; then
                echo "Choose action:"
                echo "1) Overwrite existing agent"
                echo "2) Skip copy"
                read -p "Enter choice (1-2): " choice
                case $choice in
                    1) ;;
                    *) log_info "Skipping copy"; return 0 ;;
                esac
            fi
        fi
    fi
    
    # Copy the agent
    cp "$source_file" "$dest_file" || { log_error "Failed to copy agent"; return 1; }
    log_info "Successfully copied '$agent_name' to $claude_agents_dir"
    return 0
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
      --copy-agent <filename>    Copy specific agent from local-agents/ to ~/.claude/agents/
      --select-agent             Interactively select and copy an agent from local-agents/
      --list-local-agents        List available agents in local-agents/ directory
  -h, --help                     Show this help

Automatic Local Agents Management:
  If running directory is NOT $HOME/.claude AND contains CLAUDE.md file, the script
  will automatically detect local-agents/ directory and offer to copy agents to
  current directory's .claude/agents/.
  - In interactive mode: presents a menu to select specific agents or copy all
  - In non-interactive mode: copies all agents automatically
  
  For $HOME/.claude content: Directly compares agents folder and CLAUDE.md file
  with repository content and uses interactive input to decide overwrite actions.

Examples:
  ./sync-to-github.sh --yes --prefer repo --commit --push
  ./sync-to-github.sh --copy-agent swiftui-clean-architecture-reviewer.md
  ./sync-to-github.sh --select-agent
  ./sync-to-github.sh --list-local-agents
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
            --copy-agent) COPY_LOCAL_AGENT="$2"; shift ;;
            --copy-agent=*) COPY_LOCAL_AGENT="${1#*=}" ;;
            --select-agent) COPY_LOCAL_AGENT="__INTERACTIVE__" ;;
            --list-local-agents) list_local_agents; exit 0 ;;
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

# Detect if script is run directly from outside project directory
detect_external_script_mode() {
    # Get the directory where this script is located
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Check if script directory contains dotclaude project markers
    if [ -f "$script_dir/sync-to-github.sh" ] && [ -d "$script_dir/.git" ]; then
        local remote_url
        remote_url=$(cd "$script_dir" && git remote get-url origin 2>/dev/null || echo "")
        if [[ "$remote_url" == *"dotclaude"* ]]; then
            # Script is in dotclaude project, but are we running from outside?
            if [ "$(pwd)" != "$script_dir" ]; then
                echo "true"
                return
            fi
        fi
    fi
    echo "false"
}

# Get script directory for external mode
get_script_project_dir() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "$script_dir"
}

# Set Claude directory based on context
set_claude_dir() {
    local original_pwd="${1:-$(pwd)}"
    
    # Special case: if running from $HOME/.claude, always use that directory
    if [ "$original_pwd" = "$HOME/.claude" ]; then
        CLAUDE_DIR="$HOME/.claude"
        log_info "Using user's home Claude directory: $CLAUDE_DIR"
        return
    fi
    
    # Check if current directory has CLAUDE.md (indicating Claude Code project)
    if [ -f "$original_pwd/CLAUDE.md" ]; then
        # Use current directory's .claude
        CLAUDE_DIR="$original_pwd/.claude"
        log_info "Using project-local Claude directory: $CLAUDE_DIR"
    else
        # Fall back to user's home directory
        CLAUDE_DIR="$HOME/.claude"
        log_info "Using user's home Claude directory: $CLAUDE_DIR"
    fi
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
    
    # Ensure current Claude directory exists (for local agent management)
    if [ ! -d "$CLAUDE_DIR" ]; then
        log_info "Creating Claude directory at $CLAUDE_DIR"
        mkdir -p "$CLAUDE_DIR"
    fi
    log_info "Found Claude directory at $CLAUDE_DIR"
    
    # IMPORTANT: Different directory structures for different contexts:
    # - Project-local .claude/: only agents/ (commands stay in $HOME/.claude)
    # - CLAUDE.md: stays in project root directory, never inside .claude/
    if [[ "$CLAUDE_DIR" != "$HOME/.claude" ]]; then
        # Project-local .claude directory - only agents (no commands or CLAUDE.md)
        for item_spec in "${CLAUDE_DIR_ITEMS[@]}"; do
            local item="${item_spec%:*}" type="${item_spec#*:}"
            validate_and_create_item "$item" "$type" "$CLAUDE_DIR"
        done
    else
        # $HOME/.claude directory - include all sync items
        for item_spec in "${SYNC_ITEMS[@]}"; do
            local item="${item_spec%:*}" type="${item_spec#*:}"
            validate_and_create_item "$item" "$type" "$CLAUDE_DIR"
        done
    fi
    
    # REQUIREMENT: Always ensure $HOME/.claude exists and has all sync items for comparison
    if [ "$CLAUDE_DIR" != "$HOME/.claude" ] && [ ! -d "$HOME/.claude" ]; then
        log_info "Creating $HOME/.claude directory for comparison"
        mkdir -p "$HOME/.claude"
        for item_spec in "${SYNC_ITEMS[@]}"; do
            local item="${item_spec%:*}" type="${item_spec#*:}"
            validate_and_create_item "$item" "$type" "$HOME/.claude"
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
        exclude_args=$(build_excludes "diff")
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

# Unified file operations - copy, remove, and sync with proper handling
perform_file_operation() {
    local operation="$1" src="$2" dest="$3" is_dir="$4"
    
    case "$operation" in
        copy)
            if [ "$is_dir" = true ]; then
                if command -v rsync >/dev/null 2>&1; then
                    local exclude_args
                    exclude_args=$(build_excludes "rsync")
                    mkdir -p "$dest"
                    # shellcheck disable=SC2086
                    rsync -a $exclude_args "$src"/ "$dest"/
                else
                    cp -r "$src" "$dest"
                    remove_ignored_files "$dest" || true
                fi
            else
                mkdir -p "$(dirname "$dest")"
                cp "$src" "$dest"
            fi
            ;;
        remove)
            if [ "$is_dir" = true ]; then
                rm -rf "$src"
            else
                rm -f "$src"
            fi
            ;;
    esac
}

# Convenience wrappers for backward compatibility
copy_path() {
    perform_file_operation "copy" "$1" "$2" "$3"
}

remove_path() {
    perform_file_operation "remove" "$1" "" "$2"
}

# Check if two paths have identical content
paths_identical() {
    local path1="$1" path2="$2" is_dir="$3"
    if [ "$is_dir" = true ]; then
        local exclude_args
        exclude_args=$(build_excludes "diff")
        # shellcheck disable=SC2086
        diff -r $exclude_args "$path1" "$path2" &>/dev/null
    else
        cmp -s "$path1" "$path2" &>/dev/null
    fi
}

#===============================================================================
# MENU SYSTEM AND CHOICE HANDLING
#===============================================================================

# Display menu options for different scenarios
display_menu() {
    local scenario="$1" item="$2"
    
    echo "Choose action:"
    case "$scenario" in
        diff)
            echo "1) Use local $item (overwrite repo)"
            echo "2) Use repo $item (overwrite local)"
            echo "3) Skip this $item"
            echo "4) Show detailed diff"
            read -p "Enter choice (1-4): "
            ;;
        local_only)
            echo "1) Copy to repo"
            echo "2) Delete local $item"
            echo "3) Skip"
            read -p "Enter choice (1-3): "
            ;;
        repo_only)
            echo "1) Copy to local"
            echo "2) Delete from repo"
            echo "3) Skip"
            read -p "Enter choice (1-3): "
            ;;
    esac
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

# Execute file operations based on choice - simplified logic
execute_choice() {
    local choice="$1" scenario="$2" local_path="$3" repo_path="$4" item="$5" is_dir="$6"
    
    # Handle skip choice universally
    if [ "$choice" = "3" ]; then
        log_info "Skipping $item"
        return 0
    fi
    
    # Handle show diff for diff scenario
    if [ "$scenario" = "diff" ] && [ "$choice" = "4" ]; then
        return 0  # Diff was already shown
    fi
    
    # Execute the chosen action
    case "$scenario" in
        diff)
            case "$choice" in
                1) log_info "Using local $item"
                   [ "$is_dir" = true ] && rm -rf "$repo_path"
                   copy_path "$local_path" "$repo_path" "$is_dir" ;;
                2) log_info "Using repo $item"  
                   [ "$is_dir" = true ] && rm -rf "$local_path"
                   copy_path "$repo_path" "$local_path" "$is_dir" ;;
                *) log_error "Invalid choice, skipping $item"; return 0 ;;
            esac
            ;;
        local_only)
            case "$choice" in
                1) log_info "Copying to repo"
                   copy_path "$local_path" "$repo_path" "$is_dir" ;;
                2) log_info "Deleting local $item"
                   remove_path "$local_path" "$is_dir" ;;
                *) log_error "Invalid choice, skipping $item"; return 0 ;;
            esac
            ;;
        repo_only)
            case "$choice" in
                1) log_info "Copying to local"
                   copy_path "$repo_path" "$local_path" "$is_dir" ;;
                2) log_info "Deleting from repo"
                   remove_path "$repo_path" "$is_dir" ;;
                *) log_error "Invalid choice, skipping $item"; return 0 ;;
            esac
            ;;
    esac
    
    return 1  # Changes were made
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

# Check git repository state
has_git_changes() {
    ! (git diff --quiet && git diff --cached --quiet)
}

show_git_status() {
    git status --porcelain
}

# Unified git workflow operations
stage_commit_push() {
    local commit_msg="$1" branch="$2" should_push="$3"
    
    git add . || { log_error "Failed to stage changes"; return 1; }
    git commit -m "$commit_msg" || { log_error "Failed to commit changes"; return 1; }
    
    if [ "$should_push" = true ]; then
        git push origin "$branch" || { log_error "Failed to push changes"; return 1; }
        echo -e "${GREEN}Changes committed and pushed successfully${NC}"
    else
        echo -e "${GREEN}Changes committed successfully (no push)${NC}"
    fi
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

# Setup git repository
setup_repo() {
    local LOCAL_MODE EXTERNAL_MODE
    LOCAL_MODE=$(detect_local_mode)
    EXTERNAL_MODE=$(detect_external_script_mode)
    
    if [ "$LOCAL_MODE" = "true" ]; then
        log_info "Running in local dotclaude project mode..."
        WORKING_DIR="$(pwd)"
        log_info "Using current directory: $WORKING_DIR"
    elif [ "$EXTERNAL_MODE" = "true" ]; then
        log_info "Running external script from dotclaude project directory..."
        WORKING_DIR="$(get_script_project_dir)"
        log_info "Using script's project directory: $WORKING_DIR"
        # Change to script's project directory for operations
        cd "$WORKING_DIR" || { log_error "Failed to change to script directory"; exit 1; }
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
    
    log_info "Changes detected in repository"
    show_git_status
    
    # REQUIREMENT: Never prompt for git commit under any circumstances
    log_info "Skipping git commit as per requirements"
    return 0
}

# Cleanup temporary directory
cleanup() {
    local LOCAL_MODE EXTERNAL_MODE
    LOCAL_MODE=$(detect_local_mode)
    EXTERNAL_MODE=$(detect_external_script_mode)
    
    # Only cleanup temp directory if we actually cloned a repo
    if [ "$LOCAL_MODE" != "true" ] && [ "$EXTERNAL_MODE" != "true" ] && [ -d "$TEMP_DIR" ]; then
        log_info "Cleaning up..." 
        rm -rf "$TEMP_DIR"
    fi
}

#===============================================================================
# AUTO LOCAL AGENTS MANAGEMENT
#===============================================================================

# Auto-detect and handle local agents if directory exists
handle_local_agents_auto() {
    local original_pwd="${1:-$(pwd)}"
    
    # REQUIREMENT: Only copy local agents if running directory is NOT $HOME/.claude AND contains CLAUDE.md
    if [ "$original_pwd" = "$HOME/.claude" ]; then
        return 0  # Skip if running from $HOME/.claude
    fi
    
    if [ ! -f "$original_pwd/CLAUDE.md" ]; then
        return 0  # Skip if no CLAUDE.md in current directory
    fi
    
    # Determine where to look for local-agents based on mode
    local local_agents_dir
    local LOCAL_MODE EXTERNAL_MODE
    LOCAL_MODE=$(detect_local_mode)
    EXTERNAL_MODE=$(detect_external_script_mode)
    
    if [ "$LOCAL_MODE" = "true" ]; then
        # Local mode: check current directory's local-agents
        local_agents_dir="$(pwd)/local-agents"
    elif [ "$EXTERNAL_MODE" = "true" ]; then
        # External mode: check script's project directory for local-agents
        local_agents_dir="$WORKING_DIR/local-agents"
    else
        # Remote mode: check cloned repo's local-agents (after setup_repo)
        local_agents_dir="$WORKING_DIR/local-agents"
    fi
    
    # Skip if local-agents directory doesn't exist
    if [ ! -d "$local_agents_dir" ]; then
        return 0
    fi
    
    # Check if there are any .md files in local-agents
    local agent_files=()
    for agent in "$local_agents_dir"/*.md; do
        [ -f "$agent" ] && agent_files+=("$(basename "$agent")")
    done
    
    # Skip if no agents found
    if [ ${#agent_files[@]} -eq 0 ]; then
        log_info "local-agents directory found but no agents available"
        return 0
    fi
    
    log_info "Found local-agents directory with ${#agent_files[@]} agent(s)"
    
    # In non-interactive mode, copy all agents
    if [ "$NON_INTERACTIVE" = true ]; then
        log_info "Non-interactive mode: copying all local agents to ~/.claude/agents/"
        for agent in "${agent_files[@]}"; do
            if copy_local_agent_from_dir "$agent" "$local_agents_dir"; then
                log_info "✓ Copied $agent"
            else
                log_warning "✗ Failed to copy $agent"
            fi
        done
        return 0
    fi
    
    # Interactive mode: let user choose
    echo "Found the following agents in local-agents/:"
    for i in "${!agent_files[@]}"; do
        printf "%d) %s\n" $((i+1)) "${agent_files[$i]}"
    done
    echo "$((${#agent_files[@]}+1))) Copy all agents"
    echo "$((${#agent_files[@]}+2))) Skip local agents management"
    
    while true; do
        read -p "Select option (1-$((${#agent_files[@]}+2))): " choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]]; then
            if [ "$choice" -ge 1 ] && [ "$choice" -le ${#agent_files[@]} ]; then
                # Copy specific agent
                local selected_agent="${agent_files[$((choice-1))]}"
                copy_local_agent_from_dir "$selected_agent" "$local_agents_dir"
                break
            elif [ "$choice" -eq $((${#agent_files[@]}+1)) ]; then
                # Copy all agents
                log_info "Copying all local agents..."
                for agent in "${agent_files[@]}"; do
                    if copy_local_agent_from_dir "$agent" "$local_agents_dir"; then
                        log_info "✓ Copied $agent"
                    else
                        log_warning "✗ Failed to copy $agent"
                    fi
                done
                break
            elif [ "$choice" -eq $((${#agent_files[@]}+2)) ]; then
                # Skip
                log_info "Skipping local agents management"
                break
            fi
        fi
        echo "Invalid choice. Please try again."
    done
}

# Copy agent from specific directory (helper function)
copy_local_agent_from_dir() {
    local agent_name="$1"
    local source_dir="$2"
    local claude_agents_dir="$CLAUDE_DIR/agents"
    
    local source_file="$source_dir/$agent_name"
    local dest_file="$claude_agents_dir/$agent_name"
    
    # Validate source exists
    if [ ! -f "$source_file" ]; then
        log_error "Agent '$agent_name' not found at $source_file"
        return 1
    fi
    
    # Ensure destination directory exists
    mkdir -p "$claude_agents_dir"
    
    # Check if destination already exists and prompt if different
    if [ -f "$dest_file" ]; then
        if cmp -s "$source_file" "$dest_file"; then
            log_info "Agent '$agent_name' is already up to date in $claude_agents_dir"
            return 0
        else
            log_warning "Agent '$agent_name' already exists in $claude_agents_dir but differs from source version"
            if [ "$NON_INTERACTIVE" != true ]; then
                echo "Choose action:"
                echo "1) Overwrite existing agent"
                echo "2) Skip copy"
                read -p "Enter choice (1-2): " choice
                case $choice in
                    1) ;;
                    *) log_info "Skipping copy"; return 0 ;;
                esac
            fi
        fi
    fi
    
    # Copy the agent
    cp "$source_file" "$dest_file" || { log_error "Failed to copy agent"; return 1; }
    log_info "Successfully copied '$agent_name' to $claude_agents_dir"
    return 0
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

# Special handling for $HOME/.claude content comparison
compare_home_claude_content() {
    local claude_path="$1" repo_path="$2" item="$3" is_dir="$4"
    local claude_exists repo_exists
    
    claude_exists=$(path_exists "$claude_path" "$is_dir" && echo true || echo false)
    repo_exists=$(path_exists "$repo_path" "$is_dir" && echo true || echo false)
    
    # Skip if neither exists
    if [ "$claude_exists" = false ] && [ "$repo_exists" = false ]; then
        log_warning "$item: Does not exist in either location"
        return 0
    fi
    
    # Handle cases where only one location has the item
    if [ "$claude_exists" = true ] && [ "$repo_exists" = false ]; then
        log_info "$item: Only exists in $HOME/.claude, copying to repository"
        copy_path "$claude_path" "$repo_path" "$is_dir"
        return 1
    fi
    
    if [ "$claude_exists" = false ] && [ "$repo_exists" = true ]; then
        log_info "$item: Only exists in repository, copying to $HOME/.claude"
        copy_path "$repo_path" "$claude_path" "$is_dir"
        return 1
    fi
    
    # Both exist - check if they're identical
    if paths_identical "$claude_path" "$repo_path" "$is_dir"; then
        log_info "$item: Content is identical between $HOME/.claude and repository"
        return 0
    fi
    
    # Content differs - prompt for interactive decision
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
            1)
                log_info "Using $HOME/.claude version for $item"
                [ "$is_dir" = true ] && rm -rf "$repo_path"
                copy_path "$claude_path" "$repo_path" "$is_dir"
                return 1
                ;;
            2)
                log_info "Using repository version for $item"
                [ "$is_dir" = true ] && rm -rf "$claude_path"
                copy_path "$repo_path" "$claude_path" "$is_dir"
                return 1
                ;;
            3)
                log_info "Skipping $item"
                return 0
                ;;
            4)
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

# Main execution flow
main() {
    parse_args "$@"
    
    # Handle copy-agent functionality separately (explicit agent management)
    if [ -n "$COPY_LOCAL_AGENT" ]; then
        if [ "$COPY_LOCAL_AGENT" = "__INTERACTIVE__" ]; then
            log_info "Interactive agent selection mode"
            copy_local_agent ""
        else
            log_info "Copying local agent: $COPY_LOCAL_AGENT"
            copy_local_agent "$COPY_LOCAL_AGENT"
        fi
        return $?
    fi
    
    # Save original working directory before setup_repo changes it
    local ORIGINAL_PWD="$(pwd)"
    
    # Set Claude directory based on context (current directory vs home)
    set_claude_dir "$ORIGINAL_PWD"
    
    log_info "Starting sync process for Claude directory: $CLAUDE_DIR"
    validate_environment
    log_info "Using diff tool: $(get_diff_tool)"
    setup_repo
    
    # Auto-detect and handle local agents if available (after repo setup)
    # Pass original directory to maintain correct CLAUDE.md detection
    handle_local_agents_auto "$ORIGINAL_PWD"
    
    sync_items
    commit_and_push
    cleanup
    
    echo -e "${GREEN}Sync completed successfully!${NC}"
}

# Handle script interruption
trap cleanup EXIT

# Run main function
main "$@"