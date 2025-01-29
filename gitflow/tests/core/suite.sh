#!/bin/bash
set -e

# Determine script and project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

# Run a test suite and track results
run_test_suite() {
    local suite=$1
    echo "🔄 Running test suite: $(basename "$suite")"
    
    if bash "$suite"; then
        ((TESTS_PASSED++))
        log_success "Test suite passed: $(basename "$suite")"
    else
        ((TESTS_FAILED++))
        log_error "Test suite failed: $(basename "$suite")"
        return 1
    fi
}

# Setup test environment
setup_test_env() {
    TEST_DIR=$(mktemp -d)
    echo "Setting up test environment in $TEST_DIR"
    
    # Create necessary directories
    mkdir -p "$TEST_DIR/usr/share/gitflow/lib"
    mkdir -p "$TEST_DIR/usr/share/gitflow/plugins/official"
    mkdir -p "$TEST_DIR/usr/share/gitflow/plugins/community"
    mkdir -p "$TEST_DIR/etc/gitflow"
    mkdir -p "$TEST_DIR/.config/gitflow"
    
    # Copy library files
    cp -r "$PROJECT_ROOT/usr/share/gitflow/lib/"* "$TEST_DIR/usr/share/gitflow/lib/"
    cp -r "$PROJECT_ROOT/usr/share/gitflow/plugins" "$TEST_DIR/usr/share/gitflow/"
    
    # Create git repository
    cd "$TEST_DIR"
    git init
    mkdir -p .git/hooks
    mkdir -p .git/version-control
    
    # Export test environment variables
    export GITFLOW_TEST_DIR="$TEST_DIR"
    export GITFLOW_PROJECT_ROOT="$PROJECT_ROOT"
    export HOME="$TEST_DIR"
    export GITFLOW_SYSTEM_DIR="$TEST_DIR/usr/share/gitflow"
    export GITFLOW_LIB_DIR="$GITFLOW_SYSTEM_DIR/lib"
    export GITFLOW_CONFIG_DIR="$TEST_DIR/etc/gitflow"
    export GITFLOW_USER_CONFIG_DIR="$TEST_DIR/.config/gitflow"
    export GITFLOW_TEST_ENV=1
    
    # Add gitflow to PATH
    export PATH="$PROJECT_ROOT/usr/bin:$PATH"
    
    # Source required libraries
    source "$GITFLOW_LIB_DIR/utils.sh"
    
    echo "Test environment set up with:"
    echo "GITFLOW_SYSTEM_DIR=$GITFLOW_SYSTEM_DIR"
    echo "GITFLOW_LIB_DIR=$GITFLOW_LIB_DIR"
}

# Cleanup test environment
cleanup() {
    if [ -d "$TEST_DIR" ]; then
        cd "$PROJECT_ROOT"
        rm -rf "$TEST_DIR"
    fi
}

# Set up trap for cleanup
trap cleanup EXIT

# Main test execution
main() {
    echo "Starting gitflow core tests..."
    echo "Project root: $PROJECT_ROOT"
    
    # Setup test environment
    setup_test_env
    
    # Define test order
    local test_files=(
        "test_system.sh"
        "test_config.sh"
        "test_hook_management.sh"
    )
    
    # Run test suites in order
    for test_file in "${test_files[@]}"; do
        if ! run_test_suite "$SCRIPT_DIR/$test_file"; then
            echo "❌ Test suite failed: $test_file"
            return 1
        fi
    done
    
    # Print test summary
    echo "🔄 Test Summary:"
    echo "   Passed: $TESTS_PASSED"
    echo "   Failed: $TESTS_FAILED"
    
    # Exit with failure if any tests failed
    [ $TESTS_FAILED -eq 0 ] || exit 1
}

main "$@"