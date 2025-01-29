#!/bin/bash

source "$GITFLOW_LIB_DIR/utils.sh"
source "$GITFLOW_LIB_DIR/git.sh"
source "$(dirname "$0")/../../lib/functions.sh"

# Initialize version control
mkdir -p "$VERSION_DIR"
init_version

# Prevent multiple instances
if [ -f "$PLUGIN_TMP_DIR/version_update_running" ]; then
    echo "🔄 Version update already running..." >&2
    exit 0
fi
touch "$PLUGIN_TMP_DIR/version_update_running"
trap 'rm -f "$PLUGIN_TMP_DIR/version_update_running"' EXIT

# Main execution
CURRENT_BRANCH=$(get_current_branch)
handle_version_bump "$CURRENT_BRANCH"
git add -f "$VERSION_FILE" "$BRANCH_VERSIONS_FILE"