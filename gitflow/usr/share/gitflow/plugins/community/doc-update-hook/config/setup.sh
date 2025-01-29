#!/bin/bash

source "$GITFLOW_LIB_DIR/utils.sh"

PLUGIN_CONFIG_DIR="$GITFLOW_USER_CONFIG_DIR/doc-update-hook"
PLUGIN_CONFIG_FILE="$PLUGIN_CONFIG_DIR/config"

mkdir -p "$PLUGIN_CONFIG_DIR"

# Coletar configurações específicas do plugin
read -p "Enter your webhook endpoint URL: " endpoint_url
while [ -z "$endpoint_url" ]; do
    log_error "Endpoint URL cannot be empty"
    read -p "Enter your webhook endpoint URL: " endpoint_url
done

read -p "Enter the name for your collections directory [postman_collections]: " collections_dir
collections_dir=${collections_dir:-postman_collections}

# Salvar configurações do plugin
cat > "$PLUGIN_CONFIG_FILE" <<EOF
ENDPOINT_URL="$endpoint_url"
COLLECTIONS_DIR="$collections_dir"
EOF

log_success "Doc-update-hook plugin configuration saved successfully!"