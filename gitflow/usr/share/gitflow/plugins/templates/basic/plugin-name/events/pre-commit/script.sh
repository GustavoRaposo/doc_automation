#!/bin/bash

source "$GITFLOW_LIB_DIR/utils.sh"
source "$GITFLOW_LIB_DIR/git.sh"
source "$(dirname "$0")/../../lib/functions.sh"

# Load configuration
if [ -f "$GITFLOW_USER_CONFIG_DIR/plugin-name/config.yaml" ]; then
    source "$GITFLOW_USER_CONFIG_DIR/plugin-name/config.yaml"
fi

# Clean old temporary files
clean_tmp_files

main() {
    log_info "Running pre-commit hook"
    
    # Example of temporary file usage
    local tmp_file=$(create_tmp_file "pre-commit")
    
    # Use temporary file
    echo "Processing data..." > "$tmp_file"
    
    # Process the temporary file
    if [ -f "$tmp_file" ]; then
        # Do something with the file
        cat "$tmp_file"
        rm -f "$tmp_file"
    fi
}

main "$@"