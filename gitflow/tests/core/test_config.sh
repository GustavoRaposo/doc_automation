#!/bin/bash
set -e

# Determine script and project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source dependencies
source "$PROJECT_ROOT/usr/share/gitflow/lib/utils.sh"
source "$PROJECT_ROOT/usr/share/gitflow/lib/constants.sh"

# Test configuration file handling
test_config_file() {
    echo "Testing configuration file handling..."
    local failed=0
    
    # Create test config directory
    local test_config_dir="$GITFLOW_TEST_DIR/.config/gitflow"
    mkdir -p "$test_config_dir"
    
    # Test configuration reset
    if ! gitflow --reset <<< "y"; then
        log_error "Configuration reset failed"
        failed=1
    fi
    
    # Test show configuration
    if ! gitflow --show-config 2>/dev/null; then
        log_error "Show configuration failed"
        failed=1
    fi
    
    return $failed
}

# Test configuration paths
test_config_paths() {
    echo "Testing configuration paths..."
    local failed=0
    
    # Test system configuration directory
    if [ ! -d "/etc/gitflow" ]; then
        log_error "System configuration directory missing"
        failed=1
    fi
    
    # Test user configuration directory exists
    if [ ! -d "$HOME/.config/gitflow" ]; then
        log_error "User configuration directory missing"
        failed=1
    fi
    
    return $failed
}

# Run all tests
run_config_tests() {
    local failed=0
    
    test_config_file || failed=1
    test_config_paths || failed=1
    
    if [ $failed -eq 0 ]; then
        log_success "All configuration tests passed"
    else
        log_error "Some configuration tests failed"
    fi
    
    return $failed
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_config_tests
fi