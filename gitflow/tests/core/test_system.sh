#!/bin/bash
set -e

# Determine script and project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Add the project's bin directory to PATH
export PATH="$PROJECT_ROOT/usr/bin:$PATH"

# Source dependencies
source "$PROJECT_ROOT/usr/share/gitflow/lib/utils.sh"
source "$PROJECT_ROOT/usr/share/gitflow/lib/constants.sh"

setup_test_env() {
    echo "Setting up test environment..."
    
    # Create test directory structure
    TEST_DIR=$(mktemp -d)
    echo "Test directory: $TEST_DIR"
    
    # Create necessary directories
    mkdir -p "$TEST_DIR"/{usr/bin,usr/share/gitflow/{lib,plugins/{official,community,templates/basic,metadata}},etc/gitflow}
    mkdir -p "$TEST_DIR/.config/gitflow"
    mkdir -p "$TEST_DIR/.git/hooks"
    
    # Copy required files
    cp -r "$PROJECT_ROOT/usr/share/gitflow/lib/"* "$TEST_DIR/usr/share/gitflow/lib/"
    cp -r "$PROJECT_ROOT/usr/share/gitflow/plugins" "$TEST_DIR/usr/share/gitflow/"
    cp "$PROJECT_ROOT/usr/bin/gitflow" "$TEST_DIR/usr/bin/"
    
    # Initialize plugin registry
    echo '{"plugins":{}}' > "$TEST_DIR/usr/share/gitflow/plugins/metadata/plugins.json"
    
    # Set up git repository
    cd "$TEST_DIR"
    git init >/dev/null 2>&1
    
    # Export test environment variables
    export GITFLOW_TEST_ENV=1
    export GITFLOW_SYSTEM_DIR="$TEST_DIR/usr/share/gitflow"
    export GITFLOW_LIB_DIR="$GITFLOW_SYSTEM_DIR/lib"
    export GITFLOW_CONFIG_DIR="$TEST_DIR/etc/gitflow"
    export GITFLOW_USER_CONFIG_DIR="$TEST_DIR/.config/gitflow"
    export PATH="$TEST_DIR/usr/bin:/usr/bin:/usr/local/bin:$PATH"
    
    # Set permissions
    find "$TEST_DIR" -type f -name "*.sh" -exec chmod 755 {} \;
    chmod 755 "$TEST_DIR/usr/bin/gitflow"
    
    echo "Test environment set up with:"
    echo "GITFLOW_SYSTEM_DIR=$GITFLOW_SYSTEM_DIR"
    echo "GITFLOW_LIB_DIR=$GITFLOW_LIB_DIR"
    echo "Current PATH: $PATH"

    return 0
}


# Test library loading
test_library_loading() {
    echo "Testing library loading..."
    local failed=0
    
    # First verify jq is available
    if ! command -v jq >/dev/null; then
        log_error "❌ jq not found in test environment PATH: $PATH"
        return 1
    fi
    
    # Proceed with library tests...
    local required_libs=(
        "constants.sh"
        "utils.sh"
        "config.sh"
        "hook-management.sh"
        "git.sh"
    )
    
    for lib in "${required_libs[@]}"; do
        if [ ! -f "$GITFLOW_LIB_DIR/$lib" ]; then
            log_error "Required library not found: $lib"
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

# Test directory structure
# Add to test_directory_structure function in test_system.sh
test_directory_structure() {
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
    
    # Add test for plugin tmp directories
    for plugin in "$PROJECT_ROOT/usr/share/gitflow/plugins/official"/*/ ; do
        if [ -d "$plugin" ]; then
            local tmp_dir="$plugin/tmp"
            if [ ! -d "$tmp_dir" ]; then
                mkdir -p "$tmp_dir"
                chmod 755 "$tmp_dir"
            fi
        fi
    done
    
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

# Test file permissions
test_file_permissions() {
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
    
    # Test directory permissions
    find "$PROJECT_ROOT/usr/share/gitflow" -type d -print0 | while IFS= read -r -d '' dir; do
        if [ ! -x "$dir" ]; then
            log_error "Directory not executable: $dir"
            failed=1
        fi
    done
    
    return $failed
}

# Test command line interface
test_cli() {
    echo "Testing command line interface..."
    local failed=0
    
    # Create temporary test directory
    local test_dir=$(mktemp -d)
    cd "$test_dir"
    git init >/dev/null 2>&1
    
    # Set up minimal environment
    export GITFLOW_SYSTEM_DIR="$PROJECT_ROOT/usr/share/gitflow"
    export GITFLOW_LIB_DIR="$GITFLOW_SYSTEM_DIR/lib"
    export PATH="$PROJECT_ROOT/usr/bin:$PATH"
    
    # Test help command
    if ! gitflow --help 2>&1 | grep -q "Usage: gitflow"; then
        log_error "Help command failed"
        failed=1
    else
        echo "✓ Help command works"
    fi
    
    # Test version command
    if ! gitflow --version 2>&1 | grep -q "gitflow version"; then
        log_error "Version command failed"
        failed=1
    else
        echo "✓ Version command works"
    fi
    
    # Test invalid command
    if ! gitflow --invalid-command 2>&1 | grep -q "Unknown command"; then
        log_error "Invalid command handling failed"
        failed=1
    else
        echo "✓ Invalid command handling works"
    fi
    
    # Cleanup
    cd - >/dev/null
    rm -rf "$test_dir"
    
    return $failed
}

cleanup() {
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        cd "$PROJECT_ROOT" || true
        rm -rf "$TEST_DIR"
    fi
}

# Test environment variables
test_environment() {
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

# Run all tests
run_system_tests() {
    local failed=0
    
    # Set up test environment
    if ! setup_test_env; then
        log_error "Failed to set up test environment"
        return 1
    fi
    
    # Run tests
    test_library_loading || failed=1
    test_directory_structure || failed=1
    test_file_permissions || failed=1
    test_cli || failed=1
    test_environment || failed=1
    
    if [ $failed -eq 0 ]; then
        log_success "All system tests passed"
    else
        log_error "Some system tests failed"
    fi
    
    return $failed
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_system_tests
fi