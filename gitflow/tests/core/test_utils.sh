#!/bin/bash

# Common test utilities and setup functions
test_utils_init() {
    # Export key paths calculated from the calling script
    export TEST_UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    export PROJECT_ROOT="$(cd "$TEST_UTILS_DIR/../.." && pwd)"
}

# Initialize when sourced
test_utils_init

setup_test_env() {
    echo "Setting up test environment..."
    
    # Create fresh test directory
    TEST_DIR=$(mktemp -d)
    echo "Test directory: $TEST_DIR"
    
    # Set up test environment paths
    export GITFLOW_TEST_ENV=1
    export GITFLOW_TEST_DIR="$TEST_DIR"
    export GITFLOW_SYSTEM_DIR="$TEST_DIR/usr/share/gitflow"
    export GITFLOW_LIB_DIR="$GITFLOW_SYSTEM_DIR/lib"
    export GITFLOW_CONFIG_DIR="$TEST_DIR/etc/gitflow"
    export GITFLOW_USER_CONFIG_DIR="$TEST_DIR/.config/gitflow"
    export GITFLOW_PLUGINS_DIR="$GITFLOW_SYSTEM_DIR/plugins"
    export GITFLOW_PLUGIN_METADATA_DIR="$GITFLOW_PLUGINS_DIR/metadata"
    export GITFLOW_PLUGINS_REGISTRY="$GITFLOW_PLUGIN_METADATA_DIR/plugins.json"
    export HOME="$TEST_DIR"
    
    # Create all required directories
    mkdir -p "$GITFLOW_LIB_DIR"
    mkdir -p "$GITFLOW_CONFIG_DIR"
    mkdir -p "$GITFLOW_USER_CONFIG_DIR"
    mkdir -p "$GITFLOW_PLUGINS_DIR/official"
    mkdir -p "$GITFLOW_PLUGINS_DIR/community"
    mkdir -p "$GITFLOW_PLUGINS_DIR/templates/basic"
    mkdir -p "$GITFLOW_PLUGIN_METADATA_DIR"
    
    # Copy required files
    cp -r "$PROJECT_ROOT/usr/share/gitflow/lib/"* "$GITFLOW_LIB_DIR/"
    
    # Set proper permissions
    find "$TEST_DIR" -type d -exec chmod 755 {} \;
    find "$TEST_DIR" -type f -name "*.sh" -exec chmod 755 {} \;
    
    # Initialize plugin registry
    echo '{"plugins":{}}' > "$GITFLOW_PLUGINS_REGISTRY"
    chmod 666 "$GITFLOW_PLUGINS_REGISTRY"
    
    echo "✅ Test environment set up successfully at: $TEST_DIR"
    return 0
}

verify_test_paths() {
    local critical_paths=(
        "$GITFLOW_SYSTEM_DIR"
        "$GITFLOW_LIB_DIR"
        "$GITFLOW_PLUGINS_DIR"
        "$GITFLOW_PLUGIN_METADATA_DIR"
        "$GITFLOW_CONFIG_DIR"
        "$GITFLOW_USER_CONFIG_DIR"
    )
    
    for path in "${critical_paths[@]}"; do
        if [ ! -d "$path" ]; then
            echo "❌ Critical directory missing: $path"
            return 1
        fi
    done
    return 0
}

# Enhanced cleanup function in test_utils.sh
cleanup_test_env() {
    # Only attempt cleanup if TEST_DIR is set and exists
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        echo "🧹 Cleaning up test environment..."
        
        # Try to return to PROJECT_ROOT, but don't fail if we can't
        cd "$PROJECT_ROOT" 2>/dev/null || cd /tmp
        
        # Remove test directory
        rm -rf "$TEST_DIR"
        
        echo "✅ Cleanup completed"
    fi
}

# Export the cleanup function
export -f cleanup_test_env