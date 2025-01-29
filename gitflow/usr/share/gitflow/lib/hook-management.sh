#!/bin/bash
set -e

# Required dependency checks
[ -z "$GITFLOW_LIB_DIR" ] && echo "❌ GITFLOW_LIB_DIR not set" && exit 1

# Source dependencies with error handling
for dep in constants.sh utils.sh; do
    if [ -f "$GITFLOW_LIB_DIR/$dep" ]; then
        source "$GITFLOW_LIB_DIR/$dep" || {
            echo "❌ Failed to source $dep" >&2
            exit 1
        }
    else
        echo "❌ Required dependency not found: $dep" >&2
        exit 1
    fi
done

# Initialize required variables if not set
[ -z "$GITFLOW_PLUGINS_DIR" ] && export GITFLOW_PLUGINS_DIR="$GITFLOW_SYSTEM_DIR/plugins"
[ -z "$GITFLOW_PLUGINS_REGISTRY" ] && export GITFLOW_PLUGINS_REGISTRY="$GITFLOW_PLUGINS_DIR/metadata/plugins.json"

# Ensure required directories exist
mkdir -p "$GITFLOW_PLUGINS_DIR/metadata"

# Ensure required commands are available
for cmd in jq git; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo "❌ Required command not found: $cmd" >&2
        exit 1
    fi
done

# Plugin Registry Management
register_plugin() {
    local plugin_name="$1"
    local plugin_type="$2"
    local plugin_path="$GITFLOW_PLUGINS_DIR/$plugin_type/$plugin_name"

    # Validate plugin directory
    if [ ! -d "$plugin_path" ]; then
        log_error "Plugin directory not found: $plugin_path"
        return 1
    }

    # Validate metadata file
    local metadata_file="$plugin_path/metadata.json"
    if [ ! -f "$metadata_file" ]; then
        log_error "Metadata not found for plugin $plugin_name"
        return 1
    }

    # Validate JSON format
    if ! jq empty "$metadata_file" 2>/dev/null; then
        log_error "Invalid metadata JSON for plugin $plugin_name"
        return 1
    }

    # Ensure registry directory exists
    mkdir -p "$(dirname "$GITFLOW_PLUGINS_REGISTRY")"

    # Initialize registry if needed
    if [ ! -f "$GITFLOW_PLUGINS_REGISTRY" ]; then
        echo '{"plugins":{}}' > "$GITFLOW_PLUGINS_REGISTRY"
        chmod 644 "$GITFLOW_PLUGINS_REGISTRY"
    fi

    # Create temporary file for atomic update
    local temp_file=$(mktemp)
    
    # Update registry with proper JSON handling
    if jq --arg name "$plugin_name" \
          --arg type "$plugin_type" \
          --slurpfile meta "$metadata_file" \
          '.plugins[$name] = {
              "type": $type,
              "installed": true,
              "version": ($meta[0].version // "0.0.0"),
              "description": ($meta[0].description // "No description"),
              "author": ($meta[0].author // "Unknown")
           }' "$GITFLOW_PLUGINS_REGISTRY" > "$temp_file"; then
        mv "$temp_file" "$GITFLOW_PLUGINS_REGISTRY"
        chmod 644 "$GITFLOW_PLUGINS_REGISTRY"
        log_success "Plugin $plugin_name registered successfully"
        return 0
    else
        rm -f "$temp_file"
        log_error "Failed to update plugin registry"
        return 1
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

# Hook Management
install_specific_hook() {
    local hook_name="$1"
    local repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    [ ! -d "$repo_root/.git" ] && log_error "Not a git repository" && return 1

    # Find plugin location
    local plugin_dir=""
    local plugin_types=("official" "community")
    for type in "${plugin_types[@]}"; do
        if [ -d "$GITFLOW_PLUGINS_DIR/$type/$hook_name" ]; then
            plugin_dir="$GITFLOW_PLUGINS_DIR/$type/$hook_name"
            break
        fi
    done

    [ -z "$plugin_dir" ] && log_error "Hook plugin $hook_name not found" && return 1

    # Create hook directory if needed
    mkdir -p "$repo_root/.git/hooks"

    # Install hook scripts
    local event_dir="$plugin_dir/events"
    local installed=0
    
    for event_type in "$event_dir"/*; do
        [ ! -d "$event_type" ] && continue
        
        local event_name=$(basename "$event_type")
        local script_file="$event_type/script.sh"
        local hook_file="$repo_root/.git/hooks/$event_name"

        if [ -f "$script_file" ]; then
            if [ ! -f "$hook_file" ]; then
                echo '#!/bin/bash' > "$hook_file"
                chmod +x "$hook_file"
            fi

            if ! grep -q "# Begin $hook_name" "$hook_file"; then
                cat >> "$hook_file" <<EOFHOOK

# Begin $hook_name
$(cat "$script_file")
# End $hook_name
EOFHOOK
                log_success "✅ $event_name hook for $hook_name installed successfully!"
                ((installed++))
            fi
        fi
    done

    [ $installed -eq 0 ] && log_warning "No hook scripts found in $hook_name"
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
    local plugin_types=("official" "community")
    local found_plugins=0
    
    for type in "${plugin_types[@]}"; do
        local plugins_dir="$GITFLOW_PLUGINS_DIR/$type"
        if [ -d "$plugins_dir" ] && [ -n "$(ls -A "$plugins_dir" 2>/dev/null)" ]; then
            log_info "${type^} plugins:"
            for plugin in "$plugins_dir"/*; do
                if [ -d "$plugin" ]; then
                    _display_plugin_info "$plugin" "$type"
                    ((found_plugins++))
                fi
            done
            echo
        fi
    done
    
    if [ $found_plugins -eq 0 ]; then
        log_info "No plugins found."
    fi
}

_display_plugin_info() {
    local plugin_path="$1"
    local plugin_type="$2"
    local plugin_name=$(basename "$plugin_path")
    local metadata_file="$plugin_path/metadata.json"
    
    if [ -f "$metadata_file" ]; then
        # Validate JSON before processing
        if jq empty "$metadata_file" 2>/dev/null; then
            echo "  - $plugin_name ($plugin_type)"
            # Use more robust jq filtering
            jq -r '
                . as $root |
                ["version", "description", "author"] |
                .[] |
                select($root[.] != null) |
                "    \(.): \($root[.])"
            ' "$metadata_file" 2>/dev/null || true
        else
            log_warning "Invalid metadata for plugin: $plugin_name"
            echo "  - $plugin_name ($plugin_type) [Invalid Metadata]"
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