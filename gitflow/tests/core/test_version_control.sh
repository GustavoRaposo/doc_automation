#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source dependencies
source "$PROJECT_ROOT/usr/share/gitflow/lib/utils.sh"
source "$PROJECT_ROOT/usr/share/gitflow/lib/gitflow-version-control.sh"

# Test version initialization
test_version_init() {
    echo "Testing version initialization..."
    
    # Initialize version
    if ! gitflow --init-fork; then
        log_error "Version initialization failed"
        return 1
    fi
    
    # Verify version
    local version=$(gitflow --get-version)
    if [ "$version" != "v0.0.0.0" ]; then
        log_error "Expected version v0.0.0.0, got $version"
        return 1
    fi
    
    return 0
}

# Test version manipulation
test_version_operations() {
    echo "Testing version operations..."
    
    # Test setting version
    gitflow --set-version v1.0.0.0
    local version=$(gitflow --get-version)
    if [ "$version" != "v1.0.0.0" ]; then
        log_error "Version set failed"
        return 1
    fi
    
    # Test incrementing major version
    gitflow --increment-major
    version=$(gitflow --get-version)
    if [ "$version" != "v2.0.0.0" ]; then
        log_error "Major version increment failed"
        return 1
    fi
    
    return 0
}

# Run all tests
run_version_tests() {
    local failed=0
    
    test_version_init || failed=1
    test_version_operations || failed=1
    
    return $failed
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_version_tests
fi