# GitFlow Hook Plugin Development Guide

## Plugin Structure
```
plugin-name/
├── events/                  # Event handlers
│   ├── pre-commit/         
│   │   └── script.sh       # Pre-commit hook script
│   └── post-commit/        
│       └── script.sh       # Post-commit hook script
├── config/                 # Plugin configuration
│   ├── defaults.yaml       # Default settings
│   └── schema.json        # Configuration schema
├── lib/                    # Plugin-specific libraries
│   └── functions.sh        # Shared functions
├── tests/                  # Test suite
│   ├── pre-commit.sh      # Pre-commit tests
│   └── post-commit.sh     # Post-commit tests
├── metadata.json          # Plugin metadata
└── README.md              # Plugin documentation
```

## Required Files

### 1. metadata.json
```json
{
    "name": "my-custom-hook",
    "version": "1.0.0",
    "description": "Hook description",
    "author": "Your Name",
    "email": "your.email@example.com",
    "license": "MIT",
    "events": ["pre-commit", "post-commit"],
    "dependencies": {
        "git": ">=2.34.1",
        "python3": ">=3.8.0"
    },
    "configurations": {
        "required": ["api_key"],
        "optional": ["timeout"]
    }
}
```

### 2. config/defaults.yaml
```yaml
# Default configuration
api_key: ""
timeout: 30
retry_count: 3
```

### 3. events/pre-commit/script.sh
```bash
#!/bin/bash

# Access GitFlow utilities
source "$GITFLOW_LIB_DIR/utils.sh"

# Access plugin configuration
config_file="$GITFLOW_USER_CONFIG_DIR/my-custom-hook/config.yaml"
if [ -f "$config_file" ]; then
    source "$config_file"
fi

# Implement hook logic
main() {
    # Your hook implementation
    log_info "Running pre-commit hook"
}

main "$@"
```

## Integration Guidelines

1. **Installation**
   ```bash
   gitflow --install-hook my-custom-hook
   ```

2. **Configuration**
   ```bash
   gitflow --config-hook my-custom-hook
   ```

3. **Hook Events**
   - `pre-commit`: Runs before commit is created
   - `post-commit`: Runs after commit is created
   - `pre-push`: Runs before push to remote
   - `post-merge`: Runs after merge is completed

## Development Best Practices

1. **Error Handling**
   ```bash
   if ! command_that_might_fail; then
       log_error "Operation failed"
       exit 1
   fi
   ```

2. **Configuration Validation**
   ```bash
   validate_config() {
       if [ -z "$api_key" ]; then
           log_error "API key not configured"
           exit 1
       fi
   }
   ```

3. **Logging**
   ```bash
   log_info "Starting operation"
   log_success "Operation completed"
   log_warning "Optional step skipped"
   log_error "Operation failed"
   ```

## Testing

1. Create test files in `tests/` directory
2. Test each event handler separately
3. Include configuration tests
4. Test error handling

Example test:
```bash
#!/bin/bash
source "../events/pre-commit/script.sh"

test_api_connection() {
    # Test implementation
    if ! check_api_connection; then
        echo "❌ API connection test failed"
        return 1
    fi
    echo "✅ API connection test passed"
}

test_api_connection
```

## Publishing

1. Create a branch: `feature/my-custom-hook`
2. Update documentation
3. Run tests: `./tests/run_all.sh`
4. Submit pull request

## Available GitFlow Utilities

Access these through `$GITFLOW_LIB_DIR`:

- `utils.sh`: Logging and utility functions
- `git.sh`: Git operations
- `config.sh`: Configuration management
- `hook-management.sh`: Hook lifecycle management

## Environment Variables

- `GITFLOW_SYSTEM_DIR`: System installation directory
- `GITFLOW_USER_CONFIG_DIR`: User configuration directory
- `GITFLOW_PLUGINS_DIR`: Plugin installation directory
- `GITFLOW_LIB_DIR`: Library directory

## Common Pitfalls

1. Always use `$GITFLOW_LIB_DIR` for imports
2. Handle missing configurations gracefully
3. Provide clear error messages
4. Use exit codes appropriately
5. Document all configuration options

## Example Plugin Repository

Complete example available at:
[GitFlow Example Plugin](https://github.com/gitflow/example-plugin)