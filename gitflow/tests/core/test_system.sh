#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_utils.sh"

# Source required libraries
source "$PROJECT_ROOT/usr/share/gitflow/lib/utils.sh"
source "$PROJECT_ROOT/usr/share/gitflow/lib/constants.sh"

setup_test_files() {
    # Create basic plugin structure
    mkdir -p "$TEST_DIR/usr/share/gitflow/plugins/official/version-update-hook/events"
    mkdir -p "$TEST_DIR/usr/share/gitflow/plugins/metadata"
    
    # Initialize plugin registry
    echo '{"plugins":{}}' > "$TEST_DIR/usr/share/gitflow/plugins/metadata/plugins.json"
    chmod 666 "$TEST_DIR/usr/share/gitflow/plugins/metadata/plugins.json"
    
    # Set proper permissions
    find "$TEST_DIR" -type d -exec chmod 755 {} \;
    find "$TEST_DIR" -type f -name "*.sh" -exec chmod 755 {} \;
}

system_test_library_loading() {
    echo "Testing library loading..."
    local failed=0
    
    # Set up test files first
    setup_test_files
    
    # First verify jq is available
    if ! command -v jq >/dev/null; then
        log_error "❌ jq not found in test environment PATH: $PATH"
        return 1
    fi
    
    # Define library load order
    local required_libs=(
        "constants.sh"
        "utils.sh"
        "git.sh"
        "hook-management.sh"
    )
    
    for lib in "${required_libs[@]}"; do
        if [ ! -f "$GITFLOW_LIB_DIR/$lib" ]; then
            log_error "Required library not found: $lib"
            log_error "Looking in: $GITFLOW_LIB_DIR"
            failed=1
            continue
        fi
        echo "✓ Found library: $lib"
        
        if ! source "$GITFLOW_LIB_DIR/$lib" 2>/dev/null; then
            log_error "Failed to source library: $lib"
            failed=1
        else
            echo "✓ Successfully loaded: $lib"
        fi
    done
    
    return $failed
}

# Main test function for this file
run_system_tests() {
    local failed=0
    
    system_test_library_loading || failed=1
    
    if [ $failed -eq 0 ]; then
        log_success "All system tests passed"
    else
        log_error "Some system tests failed"
    fi
    
    return $failed
}

# Only run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_system_tests
fi