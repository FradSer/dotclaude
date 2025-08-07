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

# Execute file operation based on type
execute_operation() {
    local op="$1" path="$2" dest="$3" is_dir="$4"
    
    case $op in
        copy)
            [ "$is_dir" = true ] && cp -r "$path" "$dest" || cp "$path" "$dest"
            ;;
        remove)
            [ "$is_dir" = true ] && rm -rf "$path" || rm "$path"
            ;;
    esac
}

# Handle user choice for sync operations
handle_choice() {
    local choice="$1" local_path="$2" repo_path="$3" item="$4" is_dir="$5"
    
    case $choice in
        1) log_info "Using local $item"
           [ "$is_dir" = true ] && rm -rf "$repo_path"
           execute_operation copy "$local_path" "$repo_path" "$is_dir"
           return 1 ;;
        2) log_info "Using repo $item"
           [ "$is_dir" = true ] && rm -rf "$local_path"
           execute_operation copy "$repo_path" "$local_path" "$is_dir"
           return 1 ;;
        3) log_info "Skipping $item"; return 0 ;;
        *) log_error "Invalid choice, skipping $item"; return 0 ;;
    esac
}

# Show action menu and get user choice
show_menu_and_read_choice() {
    local item="$1" scenario="$2"
    
    echo "Choose action:"
    case $scenario in
        diff)
            echo "1) Use local $item (overwrite repo)"
            echo "2) Use repo $item (overwrite local)"
            echo "3) Skip this $item"
            echo "4) Show detailed diff"
            read -p "Enter choice (1-4): " ;;
        local_only)
            echo "1) Copy to repo"
            echo "2) Delete local $item"
            echo "3) Skip"
            read -p "Enter choice (1-3): " ;;
        repo_only)
            echo "1) Copy to local"
            echo "2) Delete from repo"
            echo "3) Skip"
            read -p "Enter choice (1-3): " ;;
    esac
}

# Compare items and handle sync decisions
compare_items() {
    local local_path="$1" repo_path="$2" item="$3" is_dir="$4"
    local test_flag=$([ "$is_dir" = true ] && echo "-d" || echo "-f")
    local compare_cmd=$([ "$is_dir" = true ] && echo "diff -r" || echo "cmp -s")
    
    local local_exists=false repo_exists=false
    [ $test_flag "$local_path" ] && local_exists=true
    [ $test_flag "$repo_path" ] && repo_exists=true
    
    # Both exist - compare content
    if [ "$local_exists" = true ] && [ "$repo_exists" = true ]; then
        if $compare_cmd "$local_path" "$repo_path" >/dev/null 2>&1; then
            log_info "$item: Items are identical, skipping"
            return 0
        fi
        
        log_warning "$item: Items are different"
        echo "Local: $local_path"
        echo "Repo: $repo_path"
        echo ""
        
        show_menu_and_read_choice "$item" "diff"
        local choice="$REPLY"
        
        if [ "$choice" = "4" ]; then
            show_diff "$local_path" "$repo_path" "$is_dir"
            show_menu_and_read_choice "$item" "diff"
            choice="$REPLY"
        fi
        
        [[ "$choice" =~ ^[1-3]$ ]] && handle_choice "$choice" "$local_path" "$repo_path" "$item" "$is_dir"
        
    # Only local exists
    elif [ "$local_exists" = true ]; then
        log_warning "$item: Only exists locally"
        show_menu_and_read_choice "$item" "local_only"
        local choice="$REPLY"
        case $choice in
            1) log_info "Copying $item to repo"
               execute_operation copy "$local_path" "$repo_path" "$is_dir"; return 1 ;;
            2) log_info "Deleting local $item"
               execute_operation remove "$local_path" "" "$is_dir"; return 1 ;;
            3) log_info "Skipping $item"; return 0 ;;
        esac
        
    # Only repo exists
    elif [ "$repo_exists" = true ]; then
        log_warning "$item: Only exists in repo"
        show_menu_and_read_choice "$item" "repo_only"
        local choice="$REPLY"
        case $choice in
            1) log_info "Copying $item to local"
               execute_operation copy "$repo_path" "$local_path" "$is_dir"; return 1 ;;
            2) log_info "Deleting $item from repo"
               execute_operation remove "$repo_path" "" "$is_dir"; return 1 ;;
            3) log_info "Skipping $item"; return 0 ;;
        esac
    else
        log_warning "$item: Does not exist in either location"
        return 0
    fi
}

# Validate Claude directory and required files
validate_environment() {
    log_info "Validating Claude environment..."
    
    [ ! -d "$CLAUDE_DIR" ] && log_error "Claude directory not found at $CLAUDE_DIR" && exit 1
    log_info "Found Claude directory at $CLAUDE_DIR"
    
    for item_spec in "${ITEMS[@]}"; do
        local item="${item_spec%:*}"
        local type="${item_spec#*:}"
        local path="$CLAUDE_DIR/$item"
        local test_flag=$([ "$type" = "dir" ] && echo "-d" || echo "-f")
        
        [ ! $test_flag "$path" ] && log_error "$item not found at $path" && exit 1
    done
    
    log_info "All required files found"
}

# Setup git repository
setup_repo() {
    if [ "$LOCAL_MODE" = "true" ]; then
        log_info "Running in local dotclaude project mode..."
        WORKING_DIR="$(pwd)"
        log_info "Using current directory: $WORKING_DIR"
    else
        log_info "Setting up git repository..."
        
        [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
        git clone "$REPO_URL" "$TEMP_DIR"
        cd "$TEMP_DIR"
        git checkout "$BRANCH"
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

# Generate commit message using claude or fallback to conventional format
generate_commit_message() {
    local changes_summary
    changes_summary=$(git status --porcelain | head -10)
    
    if command -v claude >/dev/null 2>&1; then
        log_info "Using Claude to generate commit message..."
        claude --no-color <<EOF | tail -1
Generate a conventional commit message for these changes:
$changes_summary

Requirements:
- Start with feat:, fix:, docs:, style:, refactor:, test:, or chore:
- Be concise and descriptive
- No timestamp needed
- Focus on what was changed, not how
- Return only the commit message, no explanation
EOF
    else
        log_info "Claude not available, using conventional commit format..."
        local changed_items=""
        if git status --porcelain | grep -q "agents/"; then
            changed_items="${changed_items}agents "
        fi
        if git status --porcelain | grep -q "commands/"; then
            changed_items="${changed_items}commands "
        fi
        if git status --porcelain | grep -q "CLAUDE.md"; then
            changed_items="${changed_items}config "
        fi
        
        if [ -n "$changed_items" ]; then
            echo "feat: sync dotclaude ${changed_items}updates"
        else
            echo "feat: sync dotclaude configuration updates"
        fi
    fi
}

# Commit and push changes if any exist
commit_and_push() {
    log_info "Checking for changes to commit..."
    
    if git diff --quiet && git diff --cached --quiet; then
        log_info "No changes to commit"
        return
    fi
    
    log_info "Changes to be committed:"
    git status --porcelain
    
    echo -e "\nChoose action:\n1) Commit and push changes\n2) Skip commit"
    read -p "Enter choice (1-2): " choice
    
    case $choice in
        1) log_info "Committing and pushing changes..."
           git add .
           local commit_msg
           commit_msg=$(generate_commit_message)
           git commit -m "$commit_msg"
           git push origin "$BRANCH"
           echo -e "${GREEN}Changes committed and pushed successfully${NC}" ;;
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