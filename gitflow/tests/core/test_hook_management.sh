#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source dependencies after ensuring GITFLOW_LIB_DIR is set
if [ -z "$GITFLOW_LIB_DIR" ]; then
    if [ -d "$PROJECT_ROOT/usr/share/gitflow/lib" ]; then
        export GITFLOW_LIB_DIR="$PROJECT_ROOT/usr/share/gitflow/lib"
    else
        echo "❌ Cannot find gitflow library directory"
        exit 1
    fi
fi

# Source required libraries
source "$GITFLOW_LIB_DIR/utils.sh"
source "$GITFLOW_LIB_DIR/constants.sh"
source "$GITFLOW_LIB_DIR/hook-management.sh"

# Test hook installation
test_install_hook() {
    echo "Testing hook installation..."
    
    # Initialize test environment
    local TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
    git init
    
    local hook_dir="$TEST_DIR/.git/hooks"
    local plugins_dir="$TEST_DIR/usr/share/gitflow/plugins"
    
    # Set up plugin structure
    mkdir -p "$plugins_dir/official/version-update-hook/events/pre-commit"
    cp -r "$PROJECT_ROOT/usr/share/gitflow/plugins/official/version-update-hook"/* \
        "$plugins_dir/official/version-update-hook/"
    
    # Override environment variables for test
    export GITFLOW_OFFICIAL_PLUGINS_DIR="$plugins_dir/official"
    export GITFLOW_SYSTEM_DIR="$TEST_DIR/usr/share/gitflow"
    
    # Attempt to install the test hook
    if ! install_specific_hook "version-update-hook"; then
        log_error "Hook installation failed"
        cd - >/dev/null
        rm -rf "$TEST_DIR"
        return 1
    fi
    
    # Verify hook files were created
    if [ ! -f "$hook_dir/pre-commit" ]; then
        log_error "pre-commit hook not created"
        cd - >/dev/null
        rm -rf "$TEST_DIR"
        return 1
    fi
    
    # Verify hook permissions
    if [ ! -x "$hook_dir/pre-commit" ]; then
        log_error "pre-commit hook not executable"
        cd - >/dev/null
        rm -rf "$TEST_DIR"
        return 1
    fi
    
    cd - >/dev/null
    rm -rf "$TEST_DIR"
    return 0
}

# Test hook uninstallation
test_uninstall_hook() {
    echo "Testing hook uninstallation..."
    
    # Initialize test environment
    local TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
    git init
    
    local hook_dir="$TEST_DIR/.git/hooks"
    local plugins_dir="$TEST_DIR/usr/share/gitflow/plugins"
    
    # Set up plugin structure
    mkdir -p "$plugins_dir/official/version-update-hook/events/pre-commit"
    cp -r "$PROJECT_ROOT/usr/share/gitflow/plugins/official/version-update-hook"/* \
        "$plugins_dir/official/version-update-hook/"
    
    # Override environment variables for test
    export GITFLOW_OFFICIAL_PLUGINS_DIR="$plugins_dir/official"
    export GITFLOW_SYSTEM_DIR="$TEST_DIR/usr/share/gitflow"
    
    # Install and then uninstall a hook
    install_specific_hook "version-update-hook" || {
        log_error "Hook installation failed"
        cd - >/dev/null
        rm -rf "$TEST_DIR"
        return 1
    }

    if ! uninstall_hook "version-update-hook"; then
        log_error "Hook uninstallation failed"
        cd - >/dev/null
        rm -rf "$TEST_DIR"
        return 1
    fi
    
    # Verify hook was properly removed
    if [ -f "$hook_dir/pre-commit" ] && grep -q "version-update-hook" "$hook_dir/pre-commit"; then
        log_error "Hook not properly uninstalled"
        cd - >/dev/null
        rm -rf "$TEST_DIR"
        return 1
    fi
    
    cd - >/dev/null
    rm -rf "$TEST_DIR"
    return 0
}

# Run all tests
run_hook_tests() {
    local failed=0
    
    test_install_hook || failed=1
    test_uninstall_hook || failed=1
    
    if [ $failed -eq 0 ]; then
        log_success "All hook tests passed"
    else
        log_error "Some hook tests failed"
    fi
    
    return $failed
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_hook_tests
fi