#!/bin/bash
set -e

# Determine script and project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Set correct permissions for all files before any operations
set_initial_permissions() {
    echo "🔄 Setting initial file permissions..."
    
    # Force permissions with -f flag and more detailed error checking
    echo "Setting library permissions..."
    for lib in "$PROJECT_ROOT/usr/share/gitflow/lib"/*.sh; do
        if ! chmod -v 755 "$lib"; then
            echo "❌ Failed to set permissions for $lib"
            echo "Current permissions:"
            ls -l "$lib"
            exit 1
        fi
    done
    
    echo "Setting gitflow executable permissions..."
    if ! chmod -v 755 "$PROJECT_ROOT/usr/bin/gitflow"; then
        echo "❌ Failed to set permissions for gitflow executable"
        exit 1
    fi
    
    echo "Setting test script permissions..."
    for test in "$PROJECT_ROOT/tests/core"/*.sh; do
        if ! chmod -v 755 "$test"; then
            echo "❌ Failed to set permissions for $test"
            exit 1
        fi
    done
    
    echo "Setting build script permissions..."
    for script in "$PROJECT_ROOT/scripts"/*.sh; do
        if ! chmod -v 755 "$script"; then
            echo "❌ Failed to set permissions for $script"
            exit 1
        fi
    done

    # Verify permissions were actually set
    echo "Verifying library permissions:"
    ls -la "$PROJECT_ROOT/usr/share/gitflow/lib/"
    
    # Double check specific files are executable
    for lib in "$PROJECT_ROOT/usr/share/gitflow/lib"/*.sh; do
        if [ ! -x "$lib" ]; then
            echo "❌ File is still not executable: $lib"
            exit 1
        fi
    done
}

# Function to set up test environment
setup_test_environment() {
    echo "🔄 Setting up test environment..."
    
    # Ensure all required directories exist
    mkdir -p "$PROJECT_ROOT/usr/share/gitflow/lib"
    mkdir -p "$PROJECT_ROOT/usr/share/gitflow/plugins/official"
    mkdir -p "$PROJECT_ROOT/usr/share/gitflow/plugins/community"
    mkdir -p "$PROJECT_ROOT/usr/share/gitflow/plugins/templates"
    mkdir -p "$PROJECT_ROOT/usr/bin"
    mkdir -p "$PROJECT_ROOT/etc/gitflow"
    
    # Don't copy files if we're already in the correct location
    if [ "$(pwd)" != "$PROJECT_ROOT" ]; then
        # Copy library files if they're in the source directory
        if [ -d "usr/share/gitflow/lib" ]; then
            cp -r usr/share/gitflow/lib/* "$PROJECT_ROOT/usr/share/gitflow/lib/"
        fi
    fi

    # Verify required library files exist and are executable
    required_libs=(
        "constants.sh"
        "utils.sh"
        "gitflow-version-control.sh"
        "config.sh"
        "hook-management.sh"
        "git.sh"
    )

    for lib in "${required_libs[@]}"; do
        lib_path="$PROJECT_ROOT/usr/share/gitflow/lib/$lib"
        if [ ! -f "$lib_path" ]; then
            echo "❌ Required library not found: $lib"
            return 1
        fi
        chmod +x "$lib_path" || { echo "Failed to set permissions for $lib"; return 1; }
        echo "Verified and set permissions for $lib"
    done
    
    # Add gitflow to PATH for tests
    export PATH="$PROJECT_ROOT/usr/bin:$PATH"
    
    # Export required environment variables
    export GITFLOW_SYSTEM_DIR="$PROJECT_ROOT/usr/share/gitflow"
    export GITFLOW_LIB_DIR="$GITFLOW_SYSTEM_DIR/lib"
    export GITFLOW_PLUGINS_DIR="$GITFLOW_SYSTEM_DIR/plugins"
    export GITFLOW_CONFIG_DIR="$PROJECT_ROOT/etc/gitflow"

    # Debug information
    echo "Library directory contents:"
    ls -la "$PROJECT_ROOT/usr/share/gitflow/lib"
}

# Run test suite
run_tests() {
    echo "🔄 Running test suite..."
    
    # Set up test environment
    setup_test_environment
    
    # Create test directory if it doesn't exist
    mkdir -p "$PROJECT_ROOT/tests/core"
    
    # Ensure test files exist and are executable
    for test_file in suite.sh test_hook_management.sh test_version_control.sh test_system.sh test_config.sh; do
        if [ ! -f "$PROJECT_ROOT/tests/core/$test_file" ]; then
            echo "❌ Missing test file: $test_file"
            return 1
        fi
    done
    
    # Run the test suite
    if ! bash "$PROJECT_ROOT/tests/core/suite.sh"; then
        echo "❌ Tests failed - aborting build"
        return 1
    fi
    
    echo "✅ All tests passed"
    return 0
}

# Set initial permissions before anything else
set_initial_permissions

# Create a temporary build directory outside the shared folder
BUILD_DIR="/tmp/gitflow-build-$$"
mkdir -p "$BUILD_DIR"
trap 'rm -rf "$BUILD_DIR"' EXIT

# Run tests first
if ! run_tests; then
    exit 1
fi

# Copy project files to build directory
echo "Copying project files to build directory..."
cp -r "$PROJECT_ROOT/"* "$BUILD_DIR/"

# Change to build directory
cd "$BUILD_DIR"

# Debug information
echo "Setting up Debian package configuration..."
echo "Project root: $PROJECT_ROOT"
echo "Build directory: $BUILD_DIR"

# Clean up any previous build artifacts
rm -rf debian/ build/ ../*.buildinfo ../*.changes

# Ensure we have required packages
if ! dpkg -l | grep -q "^ii  debhelper "; then
    echo "Installing required packages..."
    sudo apt-get update
    sudo apt-get install -y build-essential debhelper devscripts
fi

# Create fresh build directory
mkdir -p build/

# Set umask for correct file permissions
umask 0022

# Create fresh debian directory structure
mkdir -p debian/source

# Create debian/rules with executable permissions
cat > debian/rules <<'EOF'
#!/usr/bin/make -f

# Enable verbose output
export DH_VERBOSE = 1
export DEB_BUILD_MAINT_OPTIONS = hardening=+all

%:
	dh $@

override_dh_auto_install:
	# Create required directories
	mkdir -p debian/gitflow/usr/share/gitflow
	mkdir -p debian/gitflow/usr/bin
	mkdir -p debian/gitflow/etc/gitflow
	
	# Copy files from debian/usr/ to their final locations
	cp -r debian/usr/share/gitflow/* debian/gitflow/usr/share/gitflow/
	cp -r debian/usr/bin/* debian/gitflow/usr/bin/
	
	# Set permissions
	find debian/gitflow/usr/share/gitflow -type f -name "*.sh" -exec chmod 755 {} \;
	find debian/gitflow/usr/share/gitflow -type f ! -name "*.sh" -exec chmod 644 {} \;
	find debian/gitflow/usr/share/gitflow -type d -exec chmod 755 {} \;
	chmod 755 debian/gitflow/usr/bin/gitflow

override_dh_fixperms:
	dh_fixperms
	chmod 755 debian/gitflow/usr/bin/gitflow
	find debian/gitflow/usr/share/gitflow -type f -name "*.sh" -exec chmod 755 {} \;

# Skip tests for now
override_dh_auto_test:
EOF
chmod 755 debian/rules

# Create debian/control
cat > debian/control <<EOF
Source: gitflow
Section: utils
Priority: optional
Maintainer: GitFlow Maintainers <maintainers@gitflow.org>
Build-Depends: debhelper-compat (= 13)
Standards-Version: 4.5.1
Homepage: https://github.com/yourusername/gitflow

Package: gitflow
Architecture: all
Depends: \${misc:Depends}, git (>= 2.34.1), jq, curl
Description: Git hook plugin framework
 A flexible framework for creating, managing, and using Git hook plugins.
 GitFlow provides the infrastructure and tools to develop, distribute,
 and maintain Git hooks in a modular way.
EOF

# Create debian/source/format
echo "3.0 (native)" > debian/source/format

# Create necessary build directories
mkdir -p debian/usr/share/gitflow/{lib,plugins/{official,community,templates/basic/{events,files},metadata}}
mkdir -p debian/usr/bin
mkdir -p debian/etc/gitflow

# Initialize version file for version-update-hook
VERSION_DIR="debian/usr/share/gitflow/plugins/official/version-update-hook/files"
VERSION_FILE="$VERSION_DIR/.version"
mkdir -p "$VERSION_DIR"
[ ! -f "$VERSION_FILE" ] && echo "v0.0.0.0" > "$VERSION_FILE"
chmod 644 "$VERSION_FILE"

# Initialize plugin registry
REGISTRY_FILE="debian/usr/share/gitflow/plugins/metadata/plugins.json"
mkdir -p "$(dirname "$REGISTRY_FILE")"
echo '{"plugins":{}}' > "$REGISTRY_FILE"
chmod 644 "$REGISTRY_FILE"

# Copy main executable
cp -p usr/bin/gitflow debian/usr/bin/
chmod 755 debian/usr/bin/gitflow

# Copy library files
if [ -d "usr/share/gitflow/lib" ]; then
    mkdir -p debian/usr/share/gitflow/lib
    cp -r usr/share/gitflow/lib/* debian/usr/share/gitflow/lib/
fi

# Copy plugins
for plugin_type in official community templates; do
    SRC_DIR="usr/share/gitflow/plugins/$plugin_type"
    if [ -d "$SRC_DIR" ]; then
        mkdir -p "debian/usr/share/gitflow/plugins/$plugin_type"
        cp -r "$SRC_DIR"/* "debian/usr/share/gitflow/plugins/$plugin_type/"
    fi
done

# Set correct permissions
find debian/usr/share/gitflow -type f -name "*.sh" -exec chmod 755 {} \;
find debian/usr/share/gitflow -type f ! -name "*.sh" -exec chmod 644 {} \;
find debian/usr/share/gitflow -type d -exec chmod 755 {} \;

echo "🔄 Syncing version..."
bash scripts/version-sync.sh

# Source package version if exists
[ -f .package_version ] && source .package_version

# Build the package
echo "🔄 Building package..."
if ! dpkg-buildpackage -us -uc; then
    echo "❌ Package build failed"
    exit 1
fi

# Copy the resulting package back to the project directory
mkdir -p "$PROJECT_ROOT/build"
cp -f ../*.deb "$PROJECT_ROOT/build/"

# Cleanup
rm -f ../*.buildinfo ../*.changes
rm -f .package_version

echo "✅ Build completed successfully"