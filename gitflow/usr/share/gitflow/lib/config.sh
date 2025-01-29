#!/bin/bash

source "$GITFLOW_LIB_DIR/constants.sh"
source "$GITFLOW_LIB_DIR/utils.sh"

configure_settings() {
   # Criar diretório de configuração se não existir
   mkdir -p "$GITFLOW_USER_CONFIG_DIR"

   # Verificar configuração existente
   if [ -f "$GITFLOW_USER_CONFIG" ]; then
       log_info "Found existing configuration."
       read -p "Do you want to reconfigure? (y/N) " reconfigure
       if [[ ! $reconfigure =~ ^[Yy]$ ]]; then
           return 0
       fi
   fi

   # Configuração base - não específica de plugins
   cat > "$GITFLOW_USER_CONFIG" <<EOF
# GitFlow Core Configuration
VERSION_CONTROL_ENABLED=true
EOF

   log_success "Core configuration saved successfully!"
   
   # Perguntar se deseja configurar plugins
    read -p "Would you like to configure installed plugins? (y/N) " configure_plugins
    if [[ $configure_plugins =~ ^[Yy]$ ]]; then
        # Configurar plugins instalados
        for plugin_type_dir in "$GITFLOW_OFFICIAL_PLUGINS_DIR" "$GITFLOW_COMMUNITY_PLUGINS_DIR"; do
            if [ -d "$plugin_type_dir" ]; then
                for plugin in "$plugin_type_dir"/*; do
                    if [ -d "$plugin" ] && [ -f "$plugin/config/setup.sh" ]; then
                        log_info "Configuring plugin $(basename "$plugin")..."
                        bash "$plugin/config/setup.sh"
                    fi
                done
            fi
        done
    fi
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