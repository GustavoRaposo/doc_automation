#!/bin/bash
set -e

# Determine script and project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source required libraries
source "$PROJECT_ROOT/usr/share/gitflow/lib/utils.sh"
source "$PROJECT_ROOT/usr/share/gitflow/lib/constants.sh"

# Test configuration file handling
# Test configuration file handling
test_config_file() {
    echo "Testing configuration file handling..."
    local failed=0
    
    # Initialize config file
    mkdir -p "$GITFLOW_USER_CONFIG_DIR"
    echo "# GitFlow Configuration" > "$GITFLOW_USER_CONFIG"
    
    # Test configuration reset
    if ! gitflow config reset <<< "y"; then
        log_error "Configuration reset failed"
        failed=1
    fi
    
    # Test show configuration
    # Changed the grep pattern to match the actual output (No configuration found)
    if ! gitflow config show 2>/dev/null | grep -q "No configuration found"; then
        log_error "Show configuration failed"
        failed=1
    else
        echo "✓ Empty configuration shown correctly"
    fi
    
    # Test setting configuration
    if ! gitflow config set test.key test.value; then
        log_error "Setting configuration failed"
        failed=1
    fi
    
    # Verify the configuration was set
    if ! gitflow config show | grep -q "test.key=test.value"; then
        log_error "Configuration not set correctly"
        failed=1
    else
        echo "✓ Configuration set and shown correctly"
    fi
    
    return $failed
}

# Test configuration paths
test_config_paths() {
    echo "Testing configuration paths..."
    local failed=0
    
    # Verify required directories exist
    local required_dirs=(
        "$GITFLOW_SYSTEM_DIR"
        "$GITFLOW_LIB_DIR"
        "$GITFLOW_CONFIG_DIR"
        "$GITFLOW_USER_CONFIG_DIR"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            log_error "Required directory missing: $dir"
            failed=1
        else
            echo "✓ Directory exists: $dir"
        fi
    done
    
    return $failed
}

# Run all tests
run_config_tests() {
    local failed=0
    
    # Set up test environment
    if ! setup_test_env; then
        log_error "Failed to set up test environment"
        return 1
    fi
    
    # Add gitflow to PATH
    export PATH="$PROJECT_ROOT/usr/bin:$PATH"
    
    # Run tests
    test_config_file || failed=1
    test_config_paths || failed=1
    
    if [ $failed -eq 0 ]; then
        log_success "All configuration tests passed"
    else
        log_error "Some configuration tests failed"
    fi
    
    return $failed
}

# Setup test environment
setup_test_env() {
    echo "Setting up test environment..."
    
    # Create test directory structure
    TEST_DIR=$(mktemp -d)
    echo "Test directory: $TEST_DIR"
    
    # Create necessary directories
    mkdir -p "$TEST_DIR/usr/share/gitflow/lib"
    mkdir -p "$TEST_DIR/usr/share/gitflow/plugins/official"
    mkdir -p "$TEST_DIR/usr/share/gitflow/plugins/community"
    mkdir -p "$TEST_DIR/etc/gitflow"
    mkdir -p "$TEST_DIR/.config/gitflow"
    
    # Copy required files to test environment
    cp -r "$PROJECT_ROOT/usr/share/gitflow/lib/"* "$TEST_DIR/usr/share/gitflow/lib/"
    
    # Set up git repository
    cd "$TEST_DIR"
    git init
    mkdir -p .git/hooks
    
    # Export test environment variables
    export GITFLOW_TEST_ENV=1
    export GITFLOW_SYSTEM_DIR="$TEST_DIR/usr/share/gitflow"
    export GITFLOW_LIB_DIR="$GITFLOW_SYSTEM_DIR/lib"
    export GITFLOW_CONFIG_DIR="$TEST_DIR/etc/gitflow"
    export GITFLOW_USER_CONFIG_DIR="$TEST_DIR/.config/gitflow"
    export HOME="$TEST_DIR"
    
    echo "Test environment set up at: $TEST_DIR"
    echo "GITFLOW_SYSTEM_DIR=$GITFLOW_SYSTEM_DIR"
    echo "GITFLOW_LIB_DIR=$GITFLOW_LIB_DIR"
    
    return 0
}

# Cleanup function
cleanup() {
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        cd "$PROJECT_ROOT"
        rm -rf "$TEST_DIR"
    fi
}

# Set up trap for cleanup
trap cleanup EXIT

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_config_tests
fi