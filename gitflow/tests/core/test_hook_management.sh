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
    
    # Set up hook directories and files
    setup_test_hook_files
    
    # Install the hook
    if ! install_specific_hook "version-update-hook"; then
        log_error "Hook installation failed"
        return 1
    fi
    
    # Verify installation
    verify_hook_installation
    return $?
}

# New helper function to set up test files
setup_test_hook_files() {
    # Define test-specific paths
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
    
    # Set environment variables
    export GITFLOW_TEST_ENV=1
    export GITFLOW_SYSTEM_DIR="$TEST_DIR/usr/share/gitflow"
    export GITFLOW_PLUGINS_DIR="$plugins_dir"
    export GITFLOW_PLUGINS_REGISTRY="$registry_dir/plugins.json"
}

# New helper function to verify hook installation
verify_hook_installation() {
    local hooks_dir="$TEST_DIR/repo/.git/hooks"
    local failed=0
    
    echo "Verifying hooks in directory: $hooks_dir"
    
    for hook in "pre-commit" "post-commit"; do
        if [ ! -f "$hooks_dir/$hook" ]; then
            log_error "Hook file not created: $hook"
            failed=1
            continue
        fi
        echo "Found hook file: $hook"
        
        if [ ! -x "$hooks_dir/$hook" ]; then
            log_error "Hook not executable: $hook"
            failed=1
            continue
        fi
        echo "Hook is executable: $hook"
        
        if ! grep -q "Test $hook hook" "$hooks_dir/$hook"; then
            log_error "Hook content verification failed for $hook"
            cat "$hooks_dir/$hook"
            failed=1
        else
            echo "Hook content verified: $hook"
        fi
    done
    
    return $failed
}

# Test hook uninstallation
hook_test_uninstall() {
    echo "Testing hook uninstallation..."
    
    # Create fresh test repository
    local test_repo="$TEST_DIR/repo"
    rm -rf "$test_repo"
    mkdir -p "$test_repo"
    cd "$test_repo" || exit 1
    git init
    
    # Set up fresh test files
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
    
    # Set environment variables
    export GITFLOW_TEST_ENV=1
    export GITFLOW_SYSTEM_DIR="$TEST_DIR/usr/share/gitflow"
    export GITFLOW_PLUGINS_DIR="$plugins_dir"
    export GITFLOW_PLUGINS_REGISTRY="$registry_dir/plugins.json"
    
    # First install hook
    if ! install_specific_hook "version-update-hook"; then
        log_error "Initial hook installation for uninstall test failed"
        return 1
    fi
    
    # Verify hook files exist before uninstall
    local hooks_dir="$test_repo/.git/hooks"
    for hook in "pre-commit" "post-commit"; do
        if [ ! -f "$hooks_dir/$hook" ]; then
            log_error "Hook file not created before uninstall: $hook"
            return 1
        fi
    done
    
    # Then uninstall
    if ! uninstall_hook "version-update-hook"; then
        log_error "Hook uninstallation failed"
        return 1
    fi
    
    # Verify uninstallation
    local failed=0
    for hook in "pre-commit" "post-commit"; do
        if [ -f "$hooks_dir/$hook" ] && grep -q "version-update-hook" "$hooks_dir/$hook"; then
            log_error "Hook not properly uninstalled: $hook"
            failed=1
        fi
    done
    
    [ $failed -eq 0 ] && log_success "Hook uninstallation test passed"
    return $failed
}

debug_plugin_directory() {
    local plugin_dir="$1"
    log_info "Verifying plugin structure in: $plugin_dir"
    
    # Check basic directory structure
    local required_dirs=(
        "events"
        "lib"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$plugin_dir/$dir" ]; then
            log_warning "Missing directory: $dir"
        else
            log_info "Found directory: $dir"
            
            # For events directory, check event scripts
            if [ "$dir" = "events" ]; then
                for event_dir in "$plugin_dir/$dir"/*; do
                    [ ! -d "$event_dir" ] && continue
                    
                    local event_name=$(basename "$event_dir")
                    local script_file="$event_dir/script.sh"
                    
                    if [ -f "$script_file" ]; then
                        log_info "Found event script: $event_name/script.sh"
                        if [ ! -x "$script_file" ]; then
                            log_warning "Script not executable: $event_name/script.sh"
                            chmod +x "$script_file"
                        fi
                    else
                        log_warning "Missing script for event: $event_name"
                    fi
                done
            fi
        fi
    done
    
    # Check metadata file
    local metadata_file="$plugin_dir/metadata.json"
    if [ -f "$metadata_file" ]; then
        log_info "Found metadata.json"
        if ! jq empty "$metadata_file" 2>/dev/null; then
            log_warning "Invalid JSON in metadata.json"
        fi
    else
        log_warning "Missing metadata.json"
    fi
}

# Run all tests
run_hook_tests() {
    local failed=0
    
    # Ensure we're in a clean state
    setup_test_env
    
    # Run tests
    log_info "Running hook installation test..."
    hook_test_install || failed=1
    
    log_info "Running hook uninstallation test..."
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