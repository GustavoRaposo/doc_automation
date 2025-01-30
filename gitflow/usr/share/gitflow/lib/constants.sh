#!/bin/bash

if [ -n "$CONSTANTS_LOADED" ]; then
    return 0
fi
export CONSTANTS_LOADED=1

# Basic logging functions to avoid dependency issues
_log_info() { echo "ℹ️  $1"; }
_log_error() { echo "❌ $1" >&2; }
_log_warning() { echo "⚠️  $1" >&2; }
_log_success() { echo "✅ $1"; }

# Determine system base path
if [ -n "$GITFLOW_TEST_ENV" ]; then
    # Test environment - use test directory paths
    BASE_DIR="$GITFLOW_TEST_DIR"
    GITFLOW_SYSTEM_DIR="$GITFLOW_TEST_DIR/usr/share/gitflow"
elif [ -n "$GITFLOW_WORK_DIR" ]; then
    # Build environment
    BASE_DIR="$GITFLOW_WORK_DIR"
    GITFLOW_SYSTEM_DIR="$BASE_DIR/usr/share/gitflow"
elif [ -d "/usr/share/gitflow" ]; then
    # System installation
    BASE_DIR=""
    GITFLOW_SYSTEM_DIR="/usr/share/gitflow"
else
    # Development environment
    BASE_DIR="$(pwd)"
    GITFLOW_SYSTEM_DIR="$BASE_DIR/usr/share/gitflow"
fi

# Plugin path resolution logic
resolve_plugin_path() {
    local plugin_type="$1"
    local plugin_name="$2"
    
    # Test environment takes precedence
    if [ -n "$GITFLOW_TEST_ENV" ] && [ -n "$GITFLOW_TEST_DIR" ]; then
        local test_path="$GITFLOW_TEST_DIR/usr/share/gitflow/plugins/$plugin_type/$plugin_name"
        if [ -d "$test_path" ]; then
            echo "$test_path"
            return 0
        fi
    fi
    
    # Regular environment paths
    local paths=(
        "$GITFLOW_PLUGINS_DIR/$plugin_type/$plugin_name"
        "/usr/share/gitflow/plugins/$plugin_type/$plugin_name"
    )
    
    for path in "${paths[@]}"; do
        if [ -d "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

export -f resolve_plugin_path

# System paths
GITFLOW_LIB_DIR="$GITFLOW_SYSTEM_DIR/lib"
GITFLOW_CONFIG_DIR="${BASE_DIR:+$BASE_DIR/}etc/gitflow"
GITFLOW_USER_CONFIG_DIR="$HOME/.config/gitflow"

# Plugin paths
GITFLOW_PLUGINS_DIR="$GITFLOW_SYSTEM_DIR/plugins"
GITFLOW_OFFICIAL_PLUGINS_DIR="$GITFLOW_PLUGINS_DIR/official"
GITFLOW_COMMUNITY_PLUGINS_DIR="$GITFLOW_PLUGINS_DIR/community"
GITFLOW_PLUGIN_TEMPLATE_DIR="$GITFLOW_PLUGINS_DIR/templates/basic"
GITFLOW_PLUGIN_METADATA_DIR="$GITFLOW_PLUGINS_DIR/metadata"

# Configuration files
GITFLOW_CONFIG_TEMPLATE="$GITFLOW_CONFIG_DIR/config.template"
GITFLOW_USER_CONFIG="$GITFLOW_USER_CONFIG_DIR/config"
GITFLOW_PLUGINS_REGISTRY="$GITFLOW_PLUGIN_METADATA_DIR/plugins.json"

# Version control paths with environment-specific handling
if [ -n "$GITFLOW_TEST_ENV" ] || [ -n "$GITFLOW_WORK_DIR" ]; then
    GITFLOW_VERSION_FILE="$BASE_DIR/.git/version-control/.version"
    GITFLOW_BRANCH_VERSIONS_FILE="$BASE_DIR/.git/version-control/.branch_versions"
else
    GITFLOW_VERSION_FILE=".git/version-control/.version"
    GITFLOW_BRANCH_VERSIONS_FILE=".git/version-control/.branch_versions"
fi

# Initialize registry function
initialize_registry() {
    local registry_dir="$1"
    local registry_file="$2"
    local registry_content='{"plugins":{}}'
    
    # Create directory if it doesn't exist
    if [ ! -d "$registry_dir" ]; then
        if [ -n "$GITFLOW_TEST_ENV" ]; then
            mkdir -p "$registry_dir"
        else
            sudo mkdir -p "$registry_dir"
        fi
    fi
    
    # Initialize registry file if it doesn't exist or is empty
    if [ ! -f "$registry_file" ] || [ ! -s "$registry_file" ]; then
        if [ -n "$GITFLOW_TEST_ENV" ]; then
            echo "$registry_content" > "$registry_file"
            chmod 666 "$registry_file"
        else
            echo "$registry_content" | sudo tee "$registry_file" > /dev/null
            sudo chmod 666 "$registry_file"
        fi
    fi
}

# Validate plugin registry function
validate_plugin_registry() {
    # Skip validation in test environment
    if [ -n "$GITFLOW_TEST_ENV" ]; then
        initialize_registry "$GITFLOW_PLUGIN_METADATA_DIR" "$GITFLOW_PLUGINS_REGISTRY"
        return 0
    fi
    
    # Ensure metadata directory exists and is writable
    if [ ! -d "$GITFLOW_PLUGIN_METADATA_DIR" ]; then
        sudo mkdir -p "$GITFLOW_PLUGIN_METADATA_DIR"
        sudo chmod 755 "$GITFLOW_PLUGIN_METADATA_DIR"
    fi

    # Ensure registry exists and is writable
    if [ ! -f "$GITFLOW_PLUGINS_REGISTRY" ] || [ ! -s "$GITFLOW_PLUGINS_REGISTRY" ]; then
        echo '{"plugins":{}}' | sudo tee "$GITFLOW_PLUGINS_REGISTRY" > /dev/null
        sudo chmod 666 "$GITFLOW_PLUGINS_REGISTRY"
    fi

    # Verify JSON validity
    if ! command -v jq >/dev/null 2>&1; then
        _log_warning "jq not found, skipping JSON validation"
        return 0
    fi

    if ! jq empty "$GITFLOW_PLUGINS_REGISTRY" 2>/dev/null; then
        _log_warning "Invalid registry JSON, reinitializing..."
        echo '{"plugins":{}}' | sudo tee "$GITFLOW_PLUGINS_REGISTRY" > /dev/null
        sudo chmod 666 "$GITFLOW_PLUGINS_REGISTRY"
    fi
}

# Create required directories and set permissions
for dir in "$GITFLOW_USER_CONFIG_DIR" "$GITFLOW_PLUGIN_METADATA_DIR"; do
    [ ! -d "$dir" ] && mkdir -p "$dir"
done
[ -d "$GITFLOW_USER_CONFIG_DIR" ] && chmod 700 "$GITFLOW_USER_CONFIG_DIR"

# Export all variables
export GITFLOW_SYSTEM_DIR
export GITFLOW_LIB_DIR
export GITFLOW_CONFIG_DIR
export GITFLOW_USER_CONFIG_DIR
export GITFLOW_PLUGINS_DIR
export GITFLOW_OFFICIAL_PLUGINS_DIR
export GITFLOW_COMMUNITY_PLUGINS_DIR
export GITFLOW_PLUGIN_TEMPLATE_DIR
export GITFLOW_PLUGIN_METADATA_DIR
export GITFLOW_CONFIG_TEMPLATE
export GITFLOW_USER_CONFIG
export GITFLOW_PLUGINS_REGISTRY
export GITFLOW_VERSION_FILE
export GITFLOW_BRANCH_VERSIONS_FILE

# Debug information in development/test/build environment
if [ -n "$GITFLOW_TEST_ENV" ] || [ -n "$GITFLOW_WORK_DIR" ]; then
    _log_info "Environment: $([ -n "$GITFLOW_TEST_ENV" ] && echo "Test" || echo "Build")"
    _log_info "Base path: $BASE_DIR"
    _log_info "System directory: $GITFLOW_SYSTEM_DIR"
    _log_info "Config directory: $GITFLOW_CONFIG_DIR"
fi

# Initialize registry
validate_plugin_registry