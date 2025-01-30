#!/bin/bash

# Check if we're already loaded
[ -n "$HOOK_MANAGEMENT_LOADED" ] && return 0
export HOOK_MANAGEMENT_LOADED=1

# Basic function declarations without dependencies first
_log_info() {
    echo "ℹ️  $1"
}

_log_error() {
    echo "❌ $1" >&2
}

_log_success() {
    echo "✅ $1"
}

_log_warning() {
    echo "⚠️  $1" >&2
}

# Source dependencies with proper error handling
for dep in constants.sh utils.sh git.sh; do
    if [ ! -f "$GITFLOW_LIB_DIR/$dep" ]; then
        _log_error "Required dependency not found: $dep"
        _log_error "GITFLOW_LIB_DIR=$GITFLOW_LIB_DIR"
        return 1
    fi

    if ! source "$GITFLOW_LIB_DIR/$dep" 2>/dev/null; then
        _log_error "Failed to source $dep"
        return 1
    fi
done

# Initialize required variables with fallbacks
: "${GITFLOW_PLUGINS_DIR:=$GITFLOW_SYSTEM_DIR/plugins}"
: "${GITFLOW_PLUGIN_METADATA_DIR:=$GITFLOW_PLUGINS_DIR/metadata}"
: "${GITFLOW_PLUGINS_REGISTRY:=$GITFLOW_PLUGIN_METADATA_DIR/plugins.json}"

# Directory initialization function with error handling
init_directory() {
    local dir="$1"
    local perms="${2:-755}"
    
    if [ ! -d "$dir" ]; then
        if ! mkdir -p "$dir"; then
            _log_error "Failed to create directory: $dir"
            return 1
        fi
        chmod "$perms" "$dir"
    fi
    return 0
}

# Initialize required directories with error handling
for dir in \
    "$GITFLOW_PLUGINS_DIR" \
    "$GITFLOW_PLUGIN_METADATA_DIR" \
    "$(dirname "$GITFLOW_PLUGINS_REGISTRY")"; do
    if ! init_directory "$dir"; then
        _log_error "Failed to initialize directory structure"
        return 1
    fi
done

# Initialize plugins registry with proper error handling
init_registry() {
    local registry="$GITFLOW_PLUGINS_REGISTRY"
    local temp_file
    
    # Create temporary file for atomic write
    temp_file=$(mktemp)
    
    # Initialize registry content
    echo '{"plugins":{}}' > "$temp_file"
    
    # Attempt to move file atomically
    if ! mv "$temp_file" "$registry"; then
        _log_error "Failed to initialize registry at $registry"
        rm -f "$temp_file"
        return 1
    fi
    
    chmod 644 "$registry"
    return 0
}

# Initialize registry if needed with error handling
if [ ! -f "$GITFLOW_PLUGINS_REGISTRY" ]; then
    if ! init_registry; then
        _log_error "Failed to initialize plugins registry"
        return 1
    fi
else
    # Validate existing registry
    if ! jq empty "$GITFLOW_PLUGINS_REGISTRY" 2>/dev/null; then
        _log_warning "Invalid registry detected, reinitializing..."
        if ! init_registry; then
            _log_error "Failed to reinitialize invalid registry"
            return 1
        fi
    fi
fi

# Verify final state
if [ ! -f "$GITFLOW_PLUGINS_REGISTRY" ] || [ ! -r "$GITFLOW_PLUGINS_REGISTRY" ]; then
    _log_error "Plugin registry not accessible after initialization"
    return 1
fi

_log_success "Hook management system initialized successfully"

scan_and_register_plugins() {
    local registry_content='{"plugins":{}}'
    local temp_file=$(mktemp)

    # Initialize registry with empty structure
    echo "$registry_content" > "$temp_file"

    # Only scan official plugins
    local plugins_dir="$GITFLOW_PLUGINS_DIR/official"
    [ ! -d "$plugins_dir" ] && return 0

    for plugin_dir in "$plugins_dir"/*; do
        [ ! -d "$plugin_dir" ] && continue
        
        local plugin_name=$(basename "$plugin_dir")
        local metadata_file="$plugin_dir/metadata.json"
        
        if [ -f "$metadata_file" ] && jq empty "$metadata_file" 2>/dev/null; then
            # Get plugin metadata
            local metadata=$(cat "$metadata_file")
            local version=$(echo "$metadata" | jq -r '.version // ""')
            local description=$(echo "$metadata" | jq -r '.description // ""')
            local author=$(echo "$metadata" | jq -r '.author // ""')
            
            # Update registry with plugin information
            registry_content=$(echo "$registry_content" | jq --arg name "$plugin_name" \
                --arg version "$version" \
                --arg description "$description" \
                --arg author "$author" \
                '.plugins[$name] = {
                    "type": "official",
                    "installed": false,
                    "version": $version,
                    "description": $description,
                    "author": $author
                }')
        fi
    done

    # Update the plugins registry
    if ! echo "$registry_content" | sudo tee "$GITFLOW_PLUGINS_REGISTRY" > /dev/null; then
        log_error "Failed to update plugins registry"
        rm -f "$temp_file"
        return 1
    fi

    sudo chmod 666 "$GITFLOW_PLUGINS_REGISTRY"
    rm -f "$temp_file"
    return 0
}

refresh_plugin_registry() {
    log_info "Refreshing plugin registry..."
    
    # Ensure registry directory exists
    local registry_dir=$(dirname "$GITFLOW_PLUGINS_REGISTRY")
    if [ ! -d "$registry_dir" ]; then
        sudo mkdir -p "$registry_dir"
        sudo chmod 755 "$registry_dir"
    fi

    # Scan and register all plugins
    if ! scan_and_register_plugins; then
        log_error "Failed to refresh plugin registry"
        return 1
    fi

    log_success "Plugin registry refreshed successfully"
    return 0
}

# Plugin Registry Management Functions
register_plugin() {
    local plugin_name="$1"
    local plugin_type="$2"
    
    # Refresh registry first
    refresh_plugin_registry
    
    # Read current registry
    local registry_content=$(cat "$GITFLOW_PLUGINS_REGISTRY")
    
    # Update installed status for the plugin
    registry_content=$(echo "$registry_content" | jq --arg name "$plugin_name" \
        '.plugins[$name].installed = true')
    
    # Write updated registry
    if ! echo "$registry_content" | sudo tee "$GITFLOW_PLUGINS_REGISTRY" > /dev/null; then
        log_error "Failed to update plugin registry"
        return 1
    fi
    
    sudo chmod 666 "$GITFLOW_PLUGINS_REGISTRY"
    log_success "Plugin $plugin_name registered successfully"
    return 0
}

validate_plugins_registry() {
    # Ensure the metadata directory exists with proper permissions
    if [ ! -d "$(dirname "$GITFLOW_PLUGINS_REGISTRY")" ]; then
        sudo mkdir -p "$(dirname "$GITFLOW_PLUGINS_REGISTRY")"
        sudo chmod 755 "$(dirname "$GITFLOW_PLUGINS_REGISTRY")"
    fi

    # If registry doesn't exist or is empty, initialize it
    if [ ! -f "$GITFLOW_PLUGINS_REGISTRY" ] || [ ! -s "$GITFLOW_PLUGINS_REGISTRY" ]; then
        echo '{"plugins":{}}' | sudo tee "$GITFLOW_PLUGINS_REGISTRY" > /dev/null
        sudo chown root:root "$GITFLOW_PLUGINS_REGISTRY"
        sudo chmod 666 "$GITFLOW_PLUGINS_REGISTRY"
        return 0
    fi

    # Validate JSON structure
    if ! jq empty "$GITFLOW_PLUGINS_REGISTRY" 2>/dev/null; then
        log_warning "Invalid registry file detected, reinitializing..."
        echo '{"plugins":{}}' | sudo tee "$GITFLOW_PLUGINS_REGISTRY" > /dev/null
        sudo chown root:root "$GITFLOW_PLUGINS_REGISTRY"
        sudo chmod 666 "$GITFLOW_PLUGINS_REGISTRY"
    fi

    # Ensure proper permissions
    if [ ! -w "$GITFLOW_PLUGINS_REGISTRY" ]; then
        sudo chmod 666 "$GITFLOW_PLUGINS_REGISTRY"
    fi
}

unregister_plugin() {
    local plugin_name="$1"
    [ ! -f "$GITFLOW_PLUGINS_REGISTRY" ] && return 0
    
    local temp_file=$(mktemp)
    jq "del(.plugins[\"$plugin_name\"])" "$GITFLOW_PLUGINS_REGISTRY" > "$temp_file"
    mv "$temp_file" "$GITFLOW_PLUGINS_REGISTRY"
    chmod 644 "$GITFLOW_PLUGINS_REGISTRY"
}

# Plugin Management
create_plugin() {
    local plugin_name="$1"
    local target_dir="$GITFLOW_COMMUNITY_PLUGINS_DIR/$plugin_name"

    if [ -d "$target_dir" ]; then
        log_error "Plugin $plugin_name already exists"
        return 1
    fi

    cp -r "$GITFLOW_PLUGIN_TEMPLATE_DIR" "$target_dir"
    sed -i "s/plugin-name/$plugin_name/g" "$target_dir/metadata.json"
    chmod -R 755 "$target_dir"
    
    log_success "Created plugin template in $target_dir"
    echo "Edit metadata.json and implement your hook logic in events/"
}

install_specific_hook() {
    local hook_name="$1"
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    
    [ ! -d "$repo_root/.git" ] && log_error "Not a git repository" && return 1
    
    log_info "Installing hook: $hook_name"
    log_info "Repository root: $repo_root"
    
    # Use test or system paths based on environment
    local plugins_dir="${GITFLOW_PLUGINS_DIR:-$GITFLOW_SYSTEM_DIR/plugins}"
    local registry="${GITFLOW_PLUGINS_REGISTRY:-$plugins_dir/metadata/plugins.json}"
    
    # Refresh plugin registry
    refresh_plugin_registry
    
    # Check if plugin exists in registry and is an official plugin
    if ! jq -e ".plugins[\"$hook_name\"] | select(.type == \"official\")" "$registry" >/dev/null 2>&1; then
        log_error "Official hook plugin $hook_name not found"
        return 1
    fi
    
    # Get plugin directory
    local plugin_dir="$plugins_dir/official/$hook_name"
    
    log_info "Plugin directory: $plugin_dir"
    
    # Verify plugin directory exists
    if [ ! -d "$plugin_dir" ]; then
        log_error "Plugin directory not found: $plugin_dir"
        return 1
    fi
    
    # Register plugin as installed
    register_plugin "$hook_name" "official"
    
    # Install hook scripts
    local hook_installed=0
    local event_dir="$plugin_dir/events"
    
    if [ ! -d "$event_dir" ]; then
        log_error "Events directory not found: $event_dir"
        return 1
    fi
    
    # Process each event directory
    for event_type in "$event_dir"/*; do
        [ ! -d "$event_type" ] && continue
        
        local event_name
        event_name=$(basename "$event_type")
        local script_file="$event_type/script.sh"
        local hook_file="$repo_root/.git/hooks/$event_name"
        
        if [ ! -f "$script_file" ]; then
            continue
        fi
        
        # Create or update hook file
        if [ ! -f "$hook_file" ]; then
            echo '#!/bin/bash' > "$hook_file"
        fi
        chmod +x "$hook_file"
        
        # Add hook content if not already present
        if ! grep -q "# Begin $hook_name" "$hook_file"; then
            {
                echo
                echo "# Begin $hook_name"
                cat "$script_file"
                echo "# End $hook_name"
            } >> "$hook_file"
            ((hook_installed++))
        fi
    done
    
    if [ $hook_installed -eq 0 ]; then
        log_warning "No hook scripts installed for $hook_name"
        return 1
    fi
    
    log_success "Hook $hook_name installed successfully"
    return 0
}

uninstall_hook() {
    local hook_name="$1"
    local repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    [ ! -d "$repo_root/.git" ] && log_error "Not a git repository" && return 1

    local hooks_dir="$repo_root/.git/hooks"
    local uninstalled=0

    # Process all hook files in .git/hooks
    for hook_file in "$hooks_dir"/*; do
        [ ! -f "$hook_file" ] && continue

        local tmp_file=$(mktemp)
        local in_section=0
        local content_written=0

        while IFS= read -r line; do
            if [[ $line == "# Begin $hook_name" ]]; then
                in_section=1
                continue
            fi
            if [[ $line == "# End $hook_name" ]]; then
                in_section=0
                continue
            fi
            if [ $in_section -eq 0 ]; then
                echo "$line" >> "$tmp_file"
                content_written=1
            fi
        done < "$hook_file"

        if [ $content_written -eq 1 ]; then
            sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$tmp_file"
            mv "$tmp_file" "$hook_file"
            chmod +x "$hook_file"
            ((uninstalled++))
        else
            rm -f "$hook_file"
        fi
        rm -f "$tmp_file"
    done

    [ $uninstalled -gt 0 ] && log_success "✅ Hook $hook_name uninstalled successfully!"
    return 0
}

# Plugin Information
list_available_hooks() {
    # Refresh plugin registry first
    refresh_plugin_registry

    # Read from registry
    if [ ! -f "$GITFLOW_PLUGINS_REGISTRY" ]; then
        log_error "Plugin registry not found"
        return 1
    fi

    local registry_content=$(cat "$GITFLOW_PLUGINS_REGISTRY")
    
    # Display official plugins
    log_info "Official plugins:"
    echo "$registry_content" | jq -r '.plugins | to_entries[] | 
        select(.value.type == "official") | 
        "  - \(.key) (\(.value.type))\n    version: \(.value.version)\n    description: \(.value.description)\n    author: \(.value.author)"'

    # Display community plugins
    echo
    log_info "Community plugins:"
    echo "$registry_content" | jq -r '.plugins | to_entries[] | 
        select(.value.type == "community") | 
        "  - \(.key) (\(.value.type))\n    version: \(.value.version)\n    description: \(.value.description)\n    author: \(.value.author)"'
}

_display_plugin_info() {
    local plugin_path="$1"
    local plugin_type="$2"
    local registry_content="$3"
    local plugin_name=$(basename "$plugin_path")
    local metadata_file="$plugin_path/metadata.json"
    
    if [ -f "$metadata_file" ]; then
        # Check if plugin is registered
        if echo "$registry_content" | jq -e ".plugins[\"$plugin_name\"]" >/dev/null 2>&1; then
            echo "  - $plugin_name ($plugin_type) ✓"
        else
            echo "  - $plugin_name ($plugin_type)"
        fi

        if jq empty "$metadata_file" 2>/dev/null; then
            jq -r '
                . as $root |
                ["version", "description", "author"] |
                .[] |
                select($root[.] != null) |
                "    \(.): \($root[.])"
            ' "$metadata_file" 2>/dev/null || true
        else
            log_warning "Invalid metadata for plugin: $plugin_name"
        fi
    else
        echo "  - $plugin_name ($plugin_type) [No Metadata]"
    fi
}

list_installed_plugins() {
    [ ! -f "$GITFLOW_PLUGINS_REGISTRY" ] && log_info "No plugins installed." && return 0

    echo "📦 Installed Plugins:"
    echo "---------------------"
    
    local plugins=$(jq -r '.plugins | to_entries[] | select(.value.installed == true)' "$GITFLOW_PLUGINS_REGISTRY")
    [ -z "$plugins" ] && echo "No plugins registered." && return 0

    echo "$plugins" | while IFS= read -r plugin; do
        local name=$(echo "$plugin" | jq -r '.key')
        local type=$(echo "$plugin" | jq -r '.value.type')
        local version=$(echo "$plugin" | jq -r '.value.version')
        
        if [ -d "$GITFLOW_PLUGINS_DIR/$type/$name" ]; then
            echo "✔ $name (${type^}) v${version}"
        else
            echo "⚠️ $name (${type^}) [Not Installed]"
            unregister_plugin "$name"
        fi
    done
} 