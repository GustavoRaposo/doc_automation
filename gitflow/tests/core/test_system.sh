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

# System specific test functions
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
        "config.sh"
    )
    
    for lib in "${required_libs[@]}"; do
        if [ ! -f "$GITFLOW_LIB_DIR/$lib" ]; then
            log_error "Required library not found: $lib"
            log_error "Looking in: $GITFLOW_LIB_DIR"
            failed=1
            continue
        fi
        echo "✓ Found library: $lib"
        
        # Source with error capture
        if ! output=$(source "$GITFLOW_LIB_DIR/$lib" 2>&1); then
            log_error "Failed to source library: $lib"
            log_error "Error: $output"
            failed=1
        else
            if [ -n "$output" ]; then
                echo "$output"
            fi
            echo "✓ Successfully loaded: $lib"
        fi
    done
    
    return $failed
}

system_test_directory_structure() {
    echo "Testing directory structure..."
    local failed=0
    
    local required_dirs=(
        "usr/share/gitflow"
        "usr/share/gitflow/lib"
        "usr/share/gitflow/plugins"
        "usr/share/gitflow/plugins/official"
        "usr/share/gitflow/plugins/community"
        "usr/share/gitflow/plugins/templates"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$PROJECT_ROOT/$dir" ]; then
            log_error "Required directory not found: $dir"
            failed=1
        else
            echo "✓ Found directory: $dir"
        fi
    done
    
    return $failed
}

system_test_file_permissions() {
    echo "Testing file permissions..."
    local failed=0
    
    local executables=(
        "usr/bin/gitflow"
        "usr/share/gitflow/lib/utils.sh"
        "usr/share/gitflow/lib/constants.sh"
        "usr/share/gitflow/lib/git.sh"
        "usr/share/gitflow/lib/hook-management.sh"
        "usr/share/gitflow/lib/config.sh"
    )
    
    for file in "${executables[@]}"; do
        if [ ! -x "$PROJECT_ROOT/$file" ]; then
            log_error "File not executable: $file"
            failed=1
        else
            echo "✓ Executable: $file"
        fi
    done
    
    return $failed
}

system_test_cli() {
    echo "Testing command line interface..."
    local failed=0
    local temp_output
    
    local gitflow_bin="$GITFLOW_SYSTEM_DIR/../bin/gitflow"
    
    if [ ! -x "$gitflow_bin" ]; then
        gitflow_bin="$TEST_DIR/usr/bin/gitflow"
        if [ ! -x "$gitflow_bin" ]; then
            echo "❌ gitflow executable not found or not executable"
            return 1
        fi
    fi
    
    test_command() {
        local cmd="$1"
        local expected="$2"
        local description="$3"
        temp_output=$(mktemp)
        
        echo "Testing $description..."
        if GITFLOW_DEBUG=0 "$gitflow_bin" $cmd > "$temp_output" 2>&1; then
            if grep -q "$expected" "$temp_output"; then
                echo "✓ $description works"
                rm -f "$temp_output"
                return 0
            fi
        elif [[ "$cmd" == "--invalid-xyz" ]]; then
            if grep -q "Unknown command:" "$temp_output"; then
                echo "✓ $description works"
                rm -f "$temp_output"
                return 0
            fi
        fi
        
        echo "❌ $description failed"
        echo "Output:"
        cat "$temp_output"
        rm -f "$temp_output"
        return 1
    }
    
    test_command "--help" "Usage: gitflow" "help command" || failed=1
    test_command "--version" "gitflow version" "version command" || failed=1
    test_command "--invalid-xyz" "Unknown command" "invalid command handling" || failed=1
    
    return $failed
}

system_test_environment() {
    echo "Testing environment variables..."
    local failed=0
    
    local required_vars=(
        "GITFLOW_SYSTEM_DIR"
        "GITFLOW_LIB_DIR"
        "GITFLOW_PLUGINS_DIR"
        "GITFLOW_CONFIG_DIR"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_error "Required environment variable not set: $var"
            failed=1
        else
            echo "✓ Environment variable set: $var=${!var}"
        fi
    done
    
    return $failed
}

# Main test function for this file
run_system_tests() {
    local failed=0
    
    system_test_library_loading || failed=1
    system_test_directory_structure || failed=1
    system_test_file_permissions || failed=1
    system_test_cli || failed=1
    system_test_environment || failed=1
    
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