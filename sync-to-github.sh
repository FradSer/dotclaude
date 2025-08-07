#!/bin/bash

# Sync script for dotclaude repository
# Syncs agents folder and CLAUDE.md to https://github.com/FradSer/dotclaude

set -e

# Configuration
readonly REPO_URL="https://github.com/FradSer/dotclaude.git"
readonly TEMP_DIR="/tmp/dotclaude-sync"
readonly BRANCH="main"
readonly CLAUDE_DIR="$HOME/.claude"
readonly ITEMS=("agents:dir" "commands:dir" "CLAUDE.md:file")

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

readonly LOCAL_MODE=$(detect_local_mode)

# Colors for output
readonly RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NC='\033[0m'

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

# Show diff using best available tool
show_diff() {
    local file1="$1" file2="$2" is_dir="$3"
    local tool=$(get_diff_tool)
    local args=$([ "$is_dir" = true ] && echo "-ru" || echo "-u")
    
    echo -e "\n=== DIFF START ==="
    case $tool in
        colordiff) diff $args "$file1" "$file2" | colordiff || true ;;
        git) git diff --no-index --color=always "$file1" "$file2" || true ;;
        diff) diff $args "$file1" "$file2" || true ;;
    esac
    echo -e "=== DIFF END ===\n"
}

# File operation helpers
copy_path() {
    local src="$1" dest="$2" is_dir="$3"
    [ "$is_dir" = true ] && cp -r "$src" "$dest" || cp "$src" "$dest"
}

remove_path() {
    local path="$1" is_dir="$2"
    [ "$is_dir" = true ] && rm -rf "$path" || rm -f "$path"
}

# Execute file operation based on type
execute_operation() {
    local op="$1" path="$2" dest="$3" is_dir="$4"
    
    case $op in
        copy) copy_path "$path" "$dest" "$is_dir" ;;
        remove) remove_path "$path" "$is_dir" ;;
    esac
}

# Choice action handlers
declare -A CHOICE_HANDLERS=(
    ["diff_1"]="use_local"
    ["diff_2"]="use_repo"
    ["diff_3"]="skip"
    ["local_only_1"]="copy_to_repo"
    ["local_only_2"]="delete_local"
    ["local_only_3"]="skip"
    ["repo_only_1"]="copy_to_local"
    ["repo_only_2"]="delete_from_repo"
    ["repo_only_3"]="skip"
)

# Execute choice action
execute_choice_action() {
    local action="$1" local_path="$2" repo_path="$3" item="$4" is_dir="$5"
    
    case $action in
        use_local)
            log_info "Using local $item"
            [ "$is_dir" = true ] && rm -rf "$repo_path"
            execute_operation copy "$local_path" "$repo_path" "$is_dir"
            return 1 ;;
        use_repo)
            log_info "Using repo $item"
            [ "$is_dir" = true ] && rm -rf "$local_path"
            execute_operation copy "$repo_path" "$local_path" "$is_dir"
            return 1 ;;
        copy_to_repo)
            log_info "Copying $item to repo"
            execute_operation copy "$local_path" "$repo_path" "$is_dir"
            return 1 ;;
        copy_to_local)
            log_info "Copying $item to local"
            execute_operation copy "$repo_path" "$local_path" "$is_dir"
            return 1 ;;
        delete_local)
            log_info "Deleting local $item"
            execute_operation remove "$local_path" "" "$is_dir"
            return 1 ;;
        delete_from_repo)
            log_info "Deleting $item from repo"
            execute_operation remove "$repo_path" "" "$is_dir"
            return 1 ;;
        skip)
            log_info "Skipping $item"
            return 0 ;;
        *)
            log_error "Invalid action, skipping $item"
            return 0 ;;
    esac
}

# Handle user choice for sync operations
handle_choice() {
    local choice="$1" local_path="$2" repo_path="$3" item="$4" is_dir="$5" scenario="$6"
    local action_key="${scenario}_${choice}"
    local action="${CHOICE_HANDLERS[$action_key]}"
    
    execute_choice_action "$action" "$local_path" "$repo_path" "$item" "$is_dir"
}

# Menu configuration data
declare -A MENU_CONFIGS=(
    ["diff_options"]="Use local %s (overwrite repo)|Use repo %s (overwrite local)|Skip this %s|Show detailed diff"
    ["diff_prompt"]="Enter choice (1-4): "
    ["local_only_options"]="Copy to repo|Delete local %s|Skip"
    ["local_only_prompt"]="Enter choice (1-3): "
    ["repo_only_options"]="Copy to local|Delete from repo|Skip"
    ["repo_only_prompt"]="Enter choice (1-3): "
)

# Display formatted menu options
display_menu_options() {
    local options="$1" item="$2"
    local counter=1
    
    IFS='|' read -ra OPTION_ARRAY <<< "$options"
    for option in "${OPTION_ARRAY[@]}"; do
        printf "%d) %s\n" "$counter" "$(printf "$option" "$item")"
        ((counter++))
    done
}

# Show action menu and get user choice
show_menu_and_read_choice() {
    local item="$1" scenario="$2"
    local options_key="${scenario}_options"
    local prompt_key="${scenario}_prompt"
    
    echo "Choose action:"
    display_menu_options "${MENU_CONFIGS[$options_key]}" "$item"
    read -p "${MENU_CONFIGS[$prompt_key]}"
}

# Check if path exists based on type
path_exists() {
    local path="$1" is_dir="$2"
    local test_flag=$([ "$is_dir" = true ] && echo "-d" || echo "-f")
    [ $test_flag "$path" ]
}

# Check if two paths have identical content
paths_identical() {
    local path1="$1" path2="$2" is_dir="$3"
    local compare_cmd=$([ "$is_dir" = true ] && echo "diff -r" || echo "cmp -s")
    $compare_cmd "$path1" "$path2" &>/dev/null
}

# Handle scenario where both local and repo items exist
handle_both_exist() {
    local local_path="$1" repo_path="$2" item="$3" is_dir="$4"
    
    if paths_identical "$local_path" "$repo_path" "$is_dir"; then
        log_info "$item: Items are identical, skipping"
        return 0
    fi
    
    log_warning "$item: Items are different"
    printf "Local: %s\nRepo: %s\n\n" "$local_path" "$repo_path"
    
    show_menu_and_read_choice "$item" "diff"
    local choice="$REPLY"
    
    if [ "$choice" = "4" ]; then
        show_diff "$local_path" "$repo_path" "$is_dir"
        show_menu_and_read_choice "$item" "diff"
        choice="$REPLY"
    fi
    
    [[ "$choice" =~ ^[1-3]$ ]] && handle_choice "$choice" "$local_path" "$repo_path" "$item" "$is_dir" "diff"
}

# Handle scenario where only one location has the item
handle_single_location() {
    local local_path="$1" repo_path="$2" item="$3" is_dir="$4" scenario="$5"
    
    log_warning "$item: Only exists $([[ "$scenario" == "local_only" ]] && echo "locally" || echo "in repo")"
    show_menu_and_read_choice "$item" "$scenario"
    local choice="$REPLY"
    
    handle_choice "$choice" "$local_path" "$repo_path" "$item" "$is_dir" "$scenario"
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

# Validation helper functions
validate_directory_exists() {
    local dir="$1" description="$2"
    [ ! -d "$dir" ] && log_error "$description not found at $dir" && exit 1
    log_info "Found $description at $dir"
}

validate_item_exists() {
    local item="$1" type="$2" base_dir="$3"
    local path="$base_dir/$item"
    local test_flag=$([ "$type" = "dir" ] && echo "-d" || echo "-f")
    
    [ ! $test_flag "$path" ] && log_error "$item not found at $path" && exit 1
}

# Parse item specification (name:type format)
parse_item_spec() {
    local item_spec="$1"
    echo "${item_spec%:*}" "${item_spec#*:}"
}

# Validate Claude directory and required files
validate_environment() {
    log_info "Validating Claude environment..."
    
    validate_directory_exists "$CLAUDE_DIR" "Claude directory"
    
    for item_spec in "${ITEMS[@]}"; do
        read -r item type <<< "$(parse_item_spec "$item_spec")"
        validate_item_exists "$item" "$type" "$CLAUDE_DIR"
    done
    
    log_info "All required files found"
}

# Git helper functions
clone_repo() {
    local repo_url="$1" target_dir="$2"
    [ -d "$target_dir" ] && rm -rf "$target_dir"
    git clone "$repo_url" "$target_dir" || { log_error "Failed to clone repository"; exit 1; }
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

# Setup git repository
setup_repo() {
    if [ "$LOCAL_MODE" = "true" ]; then
        log_info "Running in local dotclaude project mode..."
        WORKING_DIR="$(pwd)"
        log_info "Using current directory: $WORKING_DIR"
    else
        log_info "Setting up git repository..."
        
        clone_repo "$REPO_URL" "$TEMP_DIR"
        cd "$TEMP_DIR" || { log_error "Failed to change to temp directory"; exit 1; }
        checkout_branch "$BRANCH"
        WORKING_DIR="$TEMP_DIR"
        
        log_info "Repository setup completed"
    fi
}

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

# Check for specific file changes in git status
check_file_changes() {
    local pattern="$1"
    show_git_status | grep -q "$pattern"
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

# Generate commit message using claude or fallback to conventional format
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

# Git commit operations
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

# Commit and push changes if any exist
commit_and_push() {
    log_info "Checking for changes to commit..."
    
    if ! has_git_changes; then
        log_info "No changes to commit"
        return
    fi
    
    log_info "Changes to be committed:"
    show_git_status
    
    echo -e "\nChoose action:\n1) Commit and push changes\n2) Skip commit"
    read -p "Enter choice (1-2): " choice
    
    case $choice in
        1) 
            log_info "Committing and pushing changes..."
            stage_all_changes || return 1
            
            local commit_msg
            commit_msg=$(generate_commit_message)
            
            commit_changes "$commit_msg" || return 1
            push_changes "$BRANCH" || return 1
            
            echo -e "${GREEN}Changes committed and pushed successfully${NC}" 
            ;;
        2) log_warning "Skipping commit" ;;
        *) log_error "Invalid choice, skipping commit" ;;
    esac
}

# Cleanup temporary directory
cleanup() {
    if [ "$LOCAL_MODE" != "true" ] && [ -d "$TEMP_DIR" ]; then
        log_info "Cleaning up..." 
        rm -rf "$TEMP_DIR"
    fi
}

# Main execution flow
main() {
    log_info "Starting sync process for Claude directory: $CLAUDE_DIR"
    
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