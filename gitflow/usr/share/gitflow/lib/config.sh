#!/bin/bash

source "$GITFLOW_LIB_DIR/constants.sh"
source "$GITFLOW_LIB_DIR/utils.sh"
source "$GITFLOW_LIB_DIR/gitflow-version-control.sh"

configure_settings() {
   mkdir -p "$GITFLOW_USER_CONFIG_DIR"

   init_version

   if [ -f "$GITFLOW_USER_CONFIG" ]; then
       source "$GITFLOW_USER_CONFIG"
   fi

   if [ -f "$GITFLOW_USER_CONFIG" ]; then
       log_info "Found existing configuration."
       read -p "Do you want to reconfigure? (y/N) " reconfigure
       if [[ ! $reconfigure =~ ^[Yy]$ ]]; then
           echo "Current version: $(get_version)"
           return
       fi
   fi

   read -p "Enter your webhook endpoint URL: " endpoint_url
   while [ -z "$endpoint_url" ]; do
       log_error "Endpoint URL cannot be empty"
       read -p "Enter your webhook endpoint URL: " endpoint_url
   done

   read -p "Enter the name for your collections directory [postman_collections]: " collections_dir
   collections_dir=${collections_dir:-postman_collections}

   cat >"$GITFLOW_USER_CONFIG" <<EOF
ENDPOINT_URL="$endpoint_url"
COLLECTIONS_DIR="$collections_dir"
EOF

   log_success "Configuration saved successfully!"
   echo "Current version: $(get_version)"
}

show_config() {
   if [ -f "$GITFLOW_USER_CONFIG" ]; then
       echo "📝 Current configuration:"
       echo "------------------------"
       cat "$GITFLOW_USER_CONFIG" | sed 's/^/  /'
   else
       log_error "No configuration found. Run 'gitflow --config' to configure."
   fi
}