#!/bin/bash

source "$GITFLOW_LIB_DIR/utils.sh"

PLUGIN_TMP_DIR="$(dirname "$0")/../tmp"
PLUGIN_LIB_DIR="$(dirname "$0")"

setup_collections_dir() {
    local collections_dir="$1"
    local items_dir="${collections_dir}/items"
    
    mkdir -p "$items_dir"
    
    # Add to .gitignore if not already present
    local exclude_file=".git/info/exclude"
    if [ -f "$exclude_file" ] && ! grep -q "^${collections_dir}/" "$exclude_file"; then
        echo "${collections_dir}/" >> "$exclude_file"
    fi
}

init_main_collection() {
    local collection_file="$1"
    local repo_name="$2"
    
    if [ ! -f "$collection_file" ]; then
        cat > "$collection_file" <<EOF
{
  "info": {
    "name": "${repo_name} API Reference",
    "description": {
      "content": "API endpoints documentation",
      "type": "text/plain"
    },
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": []
}
EOF
    fi
}

check_server() {
    local endpoint_url="$1"
    local timeout="$2"
    
    if ! curl --head --fail --silent --max-time "$timeout" "$endpoint_url" >/dev/null 2>&1; then
        log_error "Server not responding ($endpoint_url)"
        return 1
    fi
    log_success "Server available"
    return 0
}

send_payload() {
    local endpoint_url="$1"
    local payload_file="$2"
    local timeout="$3"
    local retry_attempts="$4"
    local retry_delay="$5"
    
    local attempt=1
    while [ $attempt -le "$retry_attempts" ]; do
        response=$(curl -X POST "$endpoint_url" \
            -H "Accept: application/json" \
            -H "Content-Type: application/json" \
            -d @"$payload_file" \
            --fail \
            --silent \
            --show-error \
            --max-time "$timeout" \
            2>&1)
            
        if [ $? -eq 0 ]; then
            echo "$response"
            return 0
        fi
        
        log_warning "Attempt $attempt failed. Retrying in $retry_delay seconds..."
        sleep "$retry_delay"
        ((attempt++))
    done
    
    return 1
}