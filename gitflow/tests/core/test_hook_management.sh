#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source dependencies
source "$PROJECT_ROOT/usr/share/gitflow/lib/utils.sh"
source "$PROJECT_ROOT/usr/share/gitflow/lib/hook-management.sh"

# Test hook installation
test_install_hook() {
    echo "Testing hook installation..."
    local hook_dir="$GITFLOW_TEST_DIR/.git/hooks"
    
    # Attempt to install a test hook
    if ! gitflow --install-hook version-update-hook; then
        log_error "Hook installation failed"
        return 1
    fi
    
    # Verify hook files were created
    if [ ! -f "$hook_dir/pre-commit" ]; then
        log_error "pre-commit hook not created"
        return 1
    fi
    
    # Verify hook permissions
    if [ ! -x "$hook_dir/pre-commit" ]; then
        log_error "pre-commit hook not executable"
        return 1
    fi
    
    return 0
}

# Test hook uninstallation
test_uninstall_hook() {
    echo "Testing hook uninstallation..."
    local hook_dir="$GITFLOW_TEST_DIR/.git/hooks"
    
    # Install and then uninstall a hook
    gitflow --install-hook version-update-hook
    if ! gitflow --uninstall-hook version-update-hook; then
        log_error "Hook uninstallation failed"
        return 1
    fi
    
    # Verify hook was properly removed
    if grep -q "version-update-hook" "$hook_dir/pre-commit" 2>/dev/null; then
        log_error "Hook not properly uninstalled"
        return 1
    fi
    
    return 0
}

# Run all tests
run_hook_tests() {
    local failed=0
    
    test_install_hook || failed=1
    test_uninstall_hook || failed=1
    
    return $failed
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_hook_tests
fi