#!/bin/bash

set -e

source "$GITFLOW_LIB_DIR/utils.sh"
source "$GITFLOW_LIB_DIR/config.sh"
source "$(dirname "$0")/../../lib/functions.sh"
source "$(dirname "$0")/../../lib/git_utils.sh"

# Load configuration
if [ ! -f "$GITFLOW_USER_CONFIG" ]; then
    log_error "Configuration file not found. Please run 'gitflow --config' to configure."
    exit 1
fi

source "$GITFLOW_USER_CONFIG"

# Verify required variables
if [ -z "$ENDPOINT_URL" ] || [ -z "$COLLECTIONS_DIR" ]; then
    log_error "Invalid configuration. Please run 'gitflow --config' to reconfigure."
    exit 1
fi

# Set up collections directory
ITEMS_DIR="${COLLECTIONS_DIR}/items"
setup_collections_dir "$COLLECTIONS_DIR"

# Get repository information
REPO_NAME=$(get_repo_info)
MAIN_COLLECTION="${COLLECTIONS_DIR}/${REPO_NAME}_api_reference.json"

# Initialize main collection
init_main_collection "$MAIN_COLLECTION" "$REPO_NAME"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Get commit information
read -r COMMIT_HASH PARENT_HASH COMMIT_MSG AUTHOR_NAME AUTHOR_EMAIL BRANCH_NAME TIMESTAMP <<< $(get_commit_info)

if [ -z "$COMMIT_HASH" ]; then
    log_error "Could not get commit hash"
    exit 1
fi

# Generate and process documentation updates
python3 "$(dirname "$0")/../../lib/postman_utils.py" \
    --collections-dir "$COLLECTIONS_DIR" \
    --temp-dir "$TEMP_DIR" \
    --commit-hash "$COMMIT_HASH" \
    --parent-hash "$PARENT_HASH" \
    --branch "$BRANCH_NAME" \
    --author-name "$AUTHOR_NAME" \
    --author-email "$AUTHOR_EMAIL" \
    --timestamp "$TIMESTAMP" \
    --message "$COMMIT_MSG"

# Check server availability
if ! check_server "$ENDPOINT_URL" "$TIMEOUT"; then
    log_warning "Commit completed but documentation was not updated"
    exit 1
fi

# Send payload to server
PAYLOAD_FILE="$TEMP_DIR/payload.json"
if ! send_payload "$ENDPOINT_URL" "$PAYLOAD_FILE" "$TIMEOUT" "$RETRY_ATTEMPTS" "$RETRY_DELAY"; then
    log_error "Failed to send documentation update"
    exit 1
fi

# Stage changes
git add "$COLLECTIONS_DIR" 2>/dev/null || true
log_success "Documentation updated successfully"