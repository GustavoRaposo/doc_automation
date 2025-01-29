#!/bin/bash

# Determine environment and set base paths
if [ -n "$GITFLOW_TEST_ENV" ]; then
    # Test environment
    GITFLOW_SYSTEM_DIR="$GITFLOW_TEST_DIR/usr/share/gitflow"
    GITFLOW_CONFIG_DIR="$GITFLOW_TEST_DIR/etc/gitflow"
elif [ -d "/usr/share/gitflow" ] && [ ! -d "$(pwd)/usr/share/gitflow" ]; then
    # System installation (production)
    GITFLOW_SYSTEM_DIR="/usr/share/gitflow"
    GITFLOW_CONFIG_DIR="/etc/gitflow"
elif [ -d "$(pwd)/usr/share/gitflow" ]; then
    # Development environment
    GITFLOW_SYSTEM_DIR="$(pwd)/usr/share/gitflow"
    GITFLOW_CONFIG_DIR="$(pwd)/etc/gitflow"
else
    # Fallback
    GITFLOW_SYSTEM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    GITFLOW_CONFIG_DIR="/etc/gitflow"
fi

# User configuration directory
GITFLOW_USER_CONFIG_DIR="$HOME/.config/gitflow"
[ ! -d "$GITFLOW_USER_CONFIG_DIR" ] && mkdir -p "$GITFLOW_USER_CONFIG_DIR" && chmod 700 "$GITFLOW_USER_CONFIG_DIR"

# Plugin and library paths
GITFLOW_PLUGINS_DIR="$GITFLOW_SYSTEM_DIR/plugins"
GITFLOW_OFFICIAL_PLUGINS_DIR="$GITFLOW_PLUGINS_DIR/official"
GITFLOW_COMMUNITY_PLUGINS_DIR="$GITFLOW_PLUGINS_DIR/community"
GITFLOW_PLUGIN_TEMPLATE_DIR="$GITFLOW_PLUGINS_DIR/templates/basic"
GITFLOW_LIB_DIR="$GITFLOW_SYSTEM_DIR/lib"
GITFLOW_PLUGIN_METADATA_DIR="$GITFLOW_PLUGINS_DIR/metadata"

# Configuration files
GITFLOW_CONFIG_TEMPLATE="$GITFLOW_CONFIG_DIR/config.template"
GITFLOW_USER_CONFIG="$GITFLOW_USER_CONFIG_DIR/config"
GITFLOW_PLUGINS_REGISTRY="$GITFLOW_PLUGIN_METADATA_DIR/plugins.json"

# Version control paths
if [ -n "$GITFLOW_TEST_ENV" ]; then
    # Test environment - use absolute paths
    GITFLOW_VERSION_FILE="$GITFLOW_TEST_DIR/.git/version-control/.version"
    GITFLOW_BRANCH_VERSIONS_FILE="$GITFLOW_TEST_DIR/.git/version-control/.branch_versions"
else
    # Development/Production - use relative paths
    GITFLOW_VERSION_FILE=".git/version-control/.version"
    GITFLOW_BRANCH_VERSIONS_FILE=".git/version-control/.branch_versions"
fi

# Export all variables
export GITFLOW_SYSTEM_DIR
export GITFLOW_CONFIG_DIR
export GITFLOW_USER_CONFIG_DIR
export GITFLOW_PLUGINS_DIR
export GITFLOW_OFFICIAL_PLUGINS_DIR
export GITFLOW_COMMUNITY_PLUGINS_DIR
export GITFLOW_PLUGIN_TEMPLATE_DIR
export GITFLOW_LIB_DIR
export GITFLOW_PLUGIN_METADATA_DIR
export GITFLOW_CONFIG_TEMPLATE
export GITFLOW_USER_CONFIG
export GITFLOW_PLUGINS_REGISTRY
export GITFLOW_VERSION_FILE
export GITFLOW_BRANCH_VERSIONS_FILE

# Debug information in development environment
if [ -d "$(pwd)/usr/share/gitflow" ] || [ -n "$GITFLOW_TEST_ENV" ]; then
    echo "🔧 Environment: $([ -n "$GITFLOW_TEST_ENV" ] && echo "Test" || echo "Development")"
    echo "System directory: $GITFLOW_SYSTEM_DIR"
    echo "Config directory: $GITFLOW_CONFIG_DIR"
    echo "Version file: $GITFLOW_VERSION_FILE"
fi