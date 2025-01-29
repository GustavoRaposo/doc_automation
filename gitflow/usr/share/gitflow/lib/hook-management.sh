#!/bin/bash

# Source constants
source "$GITFLOW_LIB_DIR/constants.sh"

register_plugin() {
    local plugin_name="$1"
    local plugin_path="$GITFLOW_PLUGINS_DIR/community/$plugin_name"

    if [ ! -f "$GITFLOW_PLUGINS_REGISTRY" ]; then
        echo '{"plugins":{}}' > "$GITFLOW_PLUGINS_REGISTRY"
    fi

    local metadata="{}"
    if [ -f "$plugin_path/metadata.json" ]; then
        metadata=$(cat "$plugin_path/metadata.json")
    fi

    local temp_file=$(mktemp)
    jq --arg name "$plugin_name" --arg meta "$metadata" \
        '.plugins[$name] = ($meta | fromjson)' "$GITFLOW_PLUGINS_REGISTRY" > "$temp_file"
    mv "$temp_file" "$GITFLOW_PLUGINS_REGISTRY"
}

find_hooks_dir() {
    if [ -d "$GITFLOW_OFFICIAL_PLUGINS_DIR" ]; then
        echo "$GITFLOW_OFFICIAL_PLUGINS_DIR"
    elif [ -d "$GITFLOW_COMMUNITY_PLUGINS_DIR" ]; then
        echo "$GITFLOW_COMMUNITY_PLUGINS_DIR"
    else
        return 1
    fi
}

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

get_hook_metadata() {
   local hook_file="$1"
   local metadata=""
   local n=0

   while IFS= read -r line && [[ $n -lt 20 ]]; do
       if [[ $line =~ ^#[[:space:]]*git-hook:[[:space:]]*([^|]+)\|(.+)$ ]]; then
           metadata="${BASH_REMATCH[1]}|${BASH_REMATCH[2]}"
           break
       fi
       ((n++))
   done < "$hook_file"

   echo "$metadata"
}

install_specific_hook() {
    local hook_name="$1"
    local plugin_type="community"
    local repo_root=$(git rev-parse --show-toplevel)
    local version_dir="$repo_root/.git/version-control"

    # Check official plugins first
    if [ -d "$GITFLOW_OFFICIAL_PLUGINS_DIR/$hook_name" ]; then
        plugin_type="official"
    fi

    local plugin_dir="$GITFLOW_PLUGINS_DIR/$plugin_type/$hook_name"
    
    if [ ! -d "$plugin_dir" ]; then
        log_error "Hook plugin $hook_name not found"
        return 1
    }

    mkdir -p "$version_dir"

   if [ ! -f "$GITFLOW_VERSION_FILE" ]; then
       echo "v0.0.0.0" > "$GITFLOW_VERSION_FILE"
       chmod 644 "$GITFLOW_VERSION_FILE"
   fi

   if [ ! -f "$GITFLOW_BRANCH_VERSIONS_FILE" ]; then
       echo "{}" > "$GITFLOW_BRANCH_VERSIONS_FILE"
       chmod 644 "$GITFLOW_BRANCH_VERSIONS_FILE"
   fi

   if [ ! -d "$(pwd)/.git" ]; then
       log_warning "This directory is not a Git repository."
       return 1
   fi

   mkdir -p "$HOOKS_SOURCE_DIR/files"

   if [ -f "$HOOKS_SOURCE_DIR/events/pre-commit/script.sh" ]; then
       local git_hook_file=".git/hooks/pre-commit"
       if [ ! -f "$git_hook_file" ]; then
           echo '#!/bin/bash' > "$git_hook_file"
           chmod +x "$git_hook_file"
       fi
       if ! grep -q "# Begin $hook_name" "$git_hook_file"; then
           cat >> "$git_hook_file" <<EOFHOOK

# Begin $hook_name
$(cat "$HOOKS_SOURCE_DIR/events/pre-commit/script.sh")
# End $hook_name
EOFHOOK
           log_success "✅ Pre-commit hook for $hook_name installed successfully!"
       fi
   fi

   if [ -f "$HOOKS_SOURCE_DIR/events/post-commit/script.sh" ]; then
       local git_hook_file=".git/hooks/post-commit"
       if [ ! -f "$git_hook_file" ]; then
           echo '#!/bin/bash' > "$git_hook_file"
           chmod +x "$git_hook_file"
       fi
       if ! grep -q "# Begin $hook_name" "$git_hook_file"; then
           cat >> "$git_hook_file" <<EOFHOOK

# Begin $hook_name
$(cat "$HOOKS_SOURCE_DIR/events/post-commit/script.sh")
# End $hook_name
EOFHOOK
           log_success "✅ Post-commit hook for $hook_name installed successfully!"
       fi
   fi

   return 0
}

list_available_hooks() {
    log_info "Official plugins:"
    for plugin in "$GITFLOW_OFFICIAL_PLUGINS_DIR"/*; do
        if [ -d "$plugin" ]; then
            _display_plugin_info "$plugin" "official"
        fi
    done

    log_info "\nCommunity plugins:"
    for plugin in "$GITFLOW_COMMUNITY_PLUGINS_DIR"/*; do
        if [ -d "$plugin" ]; then
            _display_plugin_info "$plugin" "community"
        fi
    done
}

list_available_hooks() {
   local HOOKS_SOURCE_DIR=$(find_hooks_dir)

   if [ -z "$HOOKS_SOURCE_DIR" ]; then
       log_error "Hooks directory not found"
       return 1
   fi

   log_info "Available hooks:"
   for hook_file in "$HOOKS_SOURCE_DIR"/*; do
       if [ -f "$hook_file" ]; then
           local hook_name=$(basename "$hook_file")
           local metadata=$(get_hook_metadata "$hook_file")
           if [ -n "$metadata" ]; then
               local git_event=$(echo "$metadata" | cut -d'|' -f1 | xargs)
               local description=$(echo "$metadata" | cut -d'|' -f2)
               local installed=""

               if [ -f ".git/hooks/${git_event}" ] && grep -q "# Begin ${hook_name}" ".git/hooks/${git_event}"; then
                   installed=" [✓ Installed]"
               else
                   installed=" [✗ Not installed]"
               fi

               echo "  - $hook_name$installed"
               echo "    Event: $git_event"
               echo "    Description: $description"
           fi
       fi
   done
}

_display_plugin_info() {
    local plugin_path="$1"
    local plugin_type="$2"
    local plugin_name=$(basename "$plugin_path")
    
    if [ -f "$plugin_path/metadata.json" ]; then
        local description=$(jq -r '.description' "$plugin_path/metadata.json")
        local version=$(jq -r '.version' "$plugin_path/metadata.json")
        local author=$(jq -r '.author' "$plugin_path/metadata.json")
        
        echo "  - $plugin_name ($plugin_type) v$version"
        echo "    Author: $author"
        echo "    Description: $description"
    fi
}

uninstall_hook() {
   local hook_name="$1"
   local HOOKS_SOURCE_DIR=$(find_hooks_dir)

   if [ ! -d ".git" ]; then
       log_warning "This directory is not a Git repository."
       return 1
   fi

   if [ -z "$HOOKS_SOURCE_DIR" ]; then
       return 1
   fi

   local hook_file="$HOOKS_SOURCE_DIR/$hook_name"
   if [ ! -f "$hook_file" ]; then
       log_error "Hook $hook_name not found"
       return 1
   fi

   local metadata=$(get_hook_metadata "$hook_file")
   local git_event=$(echo "$metadata" | cut -d'|' -f1 | xargs)
   local git_hook_file=".git/hooks/${git_event}"

   if [ ! -f "$git_hook_file" ]; then
       log_error "Git hook file for event $git_event not found."
       return 1
   fi

   local tmp_file=$(mktemp)
   local in_hook_section=0
   local content_written=0

   while IFS= read -r line; do
       if [[ $line == "# Begin ${hook_name}" ]]; then
           in_hook_section=1
           continue
       fi
       if [[ $line == "# End ${hook_name}" ]]; then
           in_hook_section=0
           continue
       fi
       if [ $in_hook_section -eq 0 ]; then
           echo "$line" >> "$tmp_file"
           content_written=1
       fi
   done < "$git_hook_file"

   if [ $content_written -eq 1 ]; then
       sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$tmp_file"
       mv "$tmp_file" "$git_hook_file"
       chmod +x "$git_hook_file"
       log_success "✅ Hook $hook_name uninstalled successfully!"
   else
       rm -f "$git_hook_file"
       rm -f "$tmp_file"
       log_success "✅ Removed empty hook file: $git_hook_file"
   fi

   return 0
}