#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_utils.sh"

# Source libraries in correct order
source "$GITFLOW_LIB_DIR/constants.sh"
source "$GITFLOW_LIB_DIR/utils.sh"
source "$GITFLOW_LIB_DIR/git.sh"
source "$GITFLOW_LIB_DIR/hook-management.sh"

# Test hook installation
hook_test_install() {
    echo "Testing hook installation..."
    
    # Create and move to test git repository
    local test_repo="$TEST_DIR/repo"
    mkdir -p "$test_repo"
    cd "$test_repo" || exit 1
    git init
    
    # Define test-specific paths
    local hooks_dir="$test_repo/.git/hooks"
    local plugins_dir="$TEST_DIR/usr/share/gitflow/plugins"
    local test_plugin_dir="$plugins_dir/official/version-update-hook"
    
    # Clean and recreate plugin directory structure
    rm -rf "$test_plugin_dir"
    mkdir -p "$test_plugin_dir/events/pre-commit"
    mkdir -p "$test_plugin_dir/events/post-commit"
    mkdir -p "$test_plugin_dir/lib"
    
    # Create test hook scripts
    cat > "$test_plugin_dir/events/pre-commit/script.sh" <<'EOF'
#!/bin/bash
echo "Test pre-commit hook"
EOF
    chmod 755 "$test_plugin_dir/events/pre-commit/script.sh"
    
    cat > "$test_plugin_dir/events/post-commit/script.sh" <<'EOF'
#!/bin/bash
echo "Test post-commit hook"
EOF
    chmod 755 "$test_plugin_dir/events/post-commit/script.sh"
    
    # Create metadata
    cat > "$test_plugin_dir/metadata.json" <<'EOF'
{
    "name": "version-update-hook",
    "version": "1.0.0",
    "description": "Test hook for version updates",
    "author": "Test Author",
    "events": ["pre-commit", "post-commit"]
}
EOF
    chmod 644 "$test_plugin_dir/metadata.json"
    
    # Initialize plugin registry
    local registry_dir="$plugins_dir/metadata"
    mkdir -p "$registry_dir"
    echo '{"plugins":{}}' > "$registry_dir/plugins.json"
    chmod 666 "$registry_dir/plugins.json"
    
    # Set environment for test
    export GITFLOW_TEST_ENV=1
    export GITFLOW_SYSTEM_DIR="$TEST_DIR/usr/share/gitflow"
    export GITFLOW_PLUGINS_DIR="$plugins_dir"
    export GITFLOW_PLUGINS_REGISTRY="$registry_dir/plugins.json"
    
    # Install the hook
    if ! install_specific_hook "version-update-hook"; then
        log_error "Hook installation failed"
        return 1
    fi
    
    # Verify hook installation
    for hook in "pre-commit" "post-commit"; do
        if [ ! -f "$hooks_dir/$hook" ]; then
            log_error "Hook file not created: $hook"
            return 1
        fi
        if [ ! -x "$hooks_dir/$hook" ]; then
            log_error "Hook not executable: $hook"
            return 1
        fi
        if ! grep -q "Test $hook hook" "$hooks_dir/$hook"; then
            log_error "Hook content verification failed for $hook"
            return 1
        fi
    done
    
    return 0
}

# Test hook uninstallation
hook_test_uninstall() {
    echo "Testing hook uninstallation..."
    
    # Use the same test repository
    local test_repo="$TEST_DIR/repo"
    cd "$test_repo" || exit 1
    
    # Set environment for test
    export GITFLOW_TEST_ENV=1
    export GITFLOW_SYSTEM_DIR="$TEST_DIR/usr/share/gitflow"
    
    # First install hook
    if ! install_specific_hook "version-update-hook"; then
        log_error "Hook installation failed"
        return 1
    fi
    
    # Then uninstall
    if ! uninstall_hook "version-update-hook"; then
        log_error "Hook uninstallation failed"
        return 1
    fi
    
    # Verify uninstallation
    local hooks_dir="$test_repo/.git/hooks"
    if [ -f "$hooks_dir/pre-commit" ] && grep -q "version-update-hook" "$hooks_dir/pre-commit"; then
        log_error "Hook not properly uninstalled"
        return 1
    fi
    
    return 0
}

# Run all tests
run_hook_tests() {
    local failed=0
    
    # Ensure we're in a clean state
    setup_test_env
    
    # Run tests
    hook_test_install || failed=1
    hook_test_uninstall || failed=1
    
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