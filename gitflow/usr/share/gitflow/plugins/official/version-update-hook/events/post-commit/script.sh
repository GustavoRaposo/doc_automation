#!/bin/bash

source "$GITFLOW_LIB_DIR/utils.sh"
source "$GITFLOW_LIB_DIR/git.sh"
source "$(dirname "$0")/../../lib/functions.sh"

# Main execution
VERSION=$(get_version)
push_tag "$VERSION"