#!/bin/bash
set -e

# Determine script and project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source required libraries
source "$PROJECT_ROOT/usr/share/gitflow/lib/utils.sh"

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

# Run a test suite and track results
run_test_suite() {
    local suite=$1
    echo "🔄 Running test suite: $(basename "$suite")"
    
    if bash "$suite"; then
        ((TESTS_PASSED++))
        echo "✅ Test suite passed: $(basename "$suite")"
    else
        ((TESTS_FAILED++))
        echo "❌ Test suite failed: $(basename "$suite")"
        return 1
    fi
}

# Setup test environment
setup_test_env() {
    TEST_DIR=$(mktemp -d)
    echo "Setting up test environment in $TEST_DIR"
    
    # Create test git repository
    cd "$TEST_DIR"
    git init
    
    # Create necessary directories
    mkdir -p .git/hooks
    mkdir -p .config/gitflow
    mkdir -p /tmp/gitflow-test-etc/gitflow
    
    # Export test environment variables
    export GITFLOW_TEST_DIR="$TEST_DIR"
    export GITFLOW_PROJECT_ROOT="$PROJECT_ROOT"
    export HOME="$TEST_DIR"
    export GITFLOW_SYSTEM_DIR="$PROJECT_ROOT/usr/share/gitflow"
    export GITFLOW_CONFIG_DIR="/tmp/gitflow-test-etc/gitflow"
    
    # Create test configuration directories
    mkdir -p "$TEST_DIR/.config/gitflow"
    sudo mkdir -p /etc/gitflow || true
}

# Cleanup test environment
cleanup() {
    if [ -d "$TEST_DIR" ]; then
        cd "$PROJECT_ROOT"
        rm -rf "$TEST_DIR"
        sudo rm -rf /tmp/gitflow-test-etc
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
        "test_version_control.sh"
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