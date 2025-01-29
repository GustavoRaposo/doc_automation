# GitFlow - Git Hook Plugin Framework

A flexible framework for creating, managing, and using Git hook plugins. GitFlow provides the infrastructure and tools to develop, distribute, and maintain Git hooks in a modular way.

## Overview

GitFlow focuses on providing:
- Plugin-based hook architecture
- Easy hook development framework
- Plugin management system
- Shared utility libraries
- Configuration management
- Developer-friendly tooling

## Requirements

- Ubuntu 22.04 LTS (Jammy) or higher
- Git >= 2.34.1
- Python >= 3.8.0
- jq
- curl

## Quick Start

### Installation

```bash
# From .deb package
sudo apt-get update
sudo apt-get install -y git curl python3 jq

## Install GitFlow
cd build/
sudo dpkg -i gitflow_*_all.deb
sudo apt-get install -f
cd ..

# From source
sudo apt-get install -y build-essential devscripts debhelper
./scripts/build.sh
```

### Basic Usage

```bash
# Configure GitFlow
gitflow --config

# List available plugins
gitflow --list-hooks

# Install a plugin
gitflow --install-hook <plugin-name>

# Create a new plugin
gitflow --create-hook <plugin-name>
```

## Command Reference

### Plugin Management
- `--install-hook <name>` - Install a hook plugin
- `--uninstall-hook <name>` - Remove a hook plugin
- `--list-hooks` - Show available plugins
- `--create-hook <name>` - Create new plugin from template

### Configuration
- `--config` - Interactive configuration
- `--show-config` - Display settings
- `--reset` - Reset to defaults
- `--help` - Show usage info

## Framework Architecture

```
/usr/share/gitflow/
├── lib/                    # Core libraries
│   ├── utils.sh           # Shared utilities
│   ├── git.sh             # Git operations
│   └── hook-management.sh # Plugin management
├── plugins/               
│   ├── official/          # Official plugins
│   ├── community/         # Community plugins
│   └── templates/         # Plugin templates
└── docs/                  # Framework documentation

/etc/gitflow/              # System configuration
~/.config/gitflow/         # User configuration
```

## Plugin Development

GitFlow provides a standardized way to create Git hooks. Here's the basic plugin structure:

```
plugin-name/
├── events/                  # Event handlers
│   ├── pre-commit/         
│   │   └── script.sh       # Pre-commit hook script
│   └── post-commit/        
│       └── script.sh       # Post-commit hook script
├── lib/                    # Plugin-specific libraries
│   └── functions.sh        # Shared functions
├── tmp/                    # Temporary files directory
│   └── .gitignore         # Ignore temporary files
├── metadata.json          # Plugin metadata
└── README.md              # Plugin documentation
```

### Plugin Creation

1. Create new plugin:
```bash
gitflow --create-hook my-plugin
```

2. Define metadata:
```json
{
    "name": "my-plugin",
    "version": "1.0.0",
    "description": "Plugin description",
    "author": "Your Name",
    "email": "your.email@example.com",
    "events": ["pre-commit", "post-commit"],
    "dependencies": {
        "git": ">=2.34.1"
    }
}
```

3. Implement your hooks in the events/ directory
4. Add helper functions in lib/
5. Document usage in README.md

## Core Features

### Hook Management
- Plugin installation and removal
- Dependency management
- Event handling
- Configuration management

### Development Tools
- Plugin templates
- Shared utilities
- Testing framework
- Configuration validation

### Plugin Distribution
- Official plugin repository
- Community plugin support
- Version management
- Update mechanism

## Troubleshooting

### Common Issues
1. **Plugin Installation Fails**
   - Verify repository exists
   - Check file permissions
   - Verify dependencies

2. **Framework Issues**
   - Check configuration
   - Verify installation
   - Review logs

### Maintenance
```bash
# Remove GitFlow
sudo dpkg -r gitflow

# Clean configuration
rm -rf ~/.config/gitflow
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Write tests
4. Submit a pull request

## License

MIT License