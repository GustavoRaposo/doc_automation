#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_utils.sh"

# Set up trap for cleanup at the suite level
trap cleanup_test_env EXIT INT TERM

# First source the utilities to get logging functions
source "$PROJECT_ROOT/usr/share/gitflow/lib/utils.sh"

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

# Run a test suite and track results
run_test_suite() {
    local suite=$1
    echo "🔄 Running test suite: $(basename "$suite")"
    
    # Create a new subshell for test isolation
    if (
        setup_test_env
        bash "$suite"
    ); then
        ((TESTS_PASSED++))
        log_success "Test suite passed: $(basename "$suite")"
    else
        ((TESTS_FAILED++))
        log_error "Test suite failed: $(basename "$suite")"
        return 1
    fi
}

# Main test execution
main() {
    echo "Starting gitflow core tests..."
    
    # Define test order with priorities
    local test_files=(
        "test_system.sh"
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
    
    [ $TESTS_FAILED -eq 0 ] || exit 1
}

# Run main function
main "$@"