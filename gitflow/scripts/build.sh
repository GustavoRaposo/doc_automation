#!/bin/bash
set -e

# Determine script and project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Set correct permissions for all files before any operations
set_initial_permissions() {
    echo "🔄 Setting up working directory..."
    
    # Create temporary working directory outside shared folder
    WORK_DIR="/tmp/gitflow-work-$$"
    mkdir -p "$WORK_DIR"
    trap 'rm -rf "$WORK_DIR"' EXIT
    
    # Copy files to working directory
    echo "Copying files to working directory..."
    cp -r "$PROJECT_ROOT/"* "$WORK_DIR/"
    
    # Set permissions in working directory
    echo "Setting permissions..."
    find "$WORK_DIR" -type f -name "*.sh" -exec chmod 755 {} \;
    chmod 755 "$WORK_DIR/usr/bin/gitflow"
    
    # Export working directory for other functions
    export GITFLOW_WORK_DIR="$WORK_DIR"
    
    echo "✅ Working directory set up at: $WORK_DIR"
}

# Function to set up test environment
setup_test_environment() {
    echo "🔄 Setting up test environment..."
    
    if [ -z "$GITFLOW_WORK_DIR" ]; then
        echo "❌ Working directory not set"
        return 1
    fi
    
    # Create test directories with proper structure
    local TEST_ROOT="$GITFLOW_WORK_DIR/test_root"
    mkdir -p "$TEST_ROOT"/{usr/bin,usr/share/gitflow/{lib,plugins/{official,community,templates/basic,metadata}},etc/gitflow}
    mkdir -p "$TEST_ROOT/.config/gitflow"
    
    # Copy required files
    echo "Copying files to test environment..."
    cp -r "$GITFLOW_WORK_DIR/usr/share/gitflow/lib/"* "$TEST_ROOT/usr/share/gitflow/lib/" || {
        echo "❌ Failed to copy library files"
        return 1
    }
    
    cp -r "$GITFLOW_WORK_DIR/usr/share/gitflow/plugins"/* "$TEST_ROOT/usr/share/gitflow/plugins/" || {
        echo "❌ Failed to copy plugin files"
        return 1
    }
    
    cp "$GITFLOW_WORK_DIR/usr/bin/gitflow" "$TEST_ROOT/usr/bin/" || {
        echo "❌ Failed to copy gitflow executable"
        return 1
    }
    
    # Initialize plugins registry
    echo '{"plugins":{}}' > "$TEST_ROOT/usr/share/gitflow/plugins/metadata/plugins.json"
    
    # Set permissions
    find "$TEST_ROOT" -type f -name "*.sh" -exec chmod 755 {} \;
    chmod 755 "$TEST_ROOT/usr/bin/gitflow"
    chmod 644 "$TEST_ROOT/usr/share/gitflow/plugins/metadata/plugins.json"
    
    # Set up test environment variables
    export GITFLOW_TEST_ENV=1
    export GITFLOW_SYSTEM_DIR="$TEST_ROOT/usr/share/gitflow"
    export GITFLOW_LIB_DIR="$GITFLOW_SYSTEM_DIR/lib"
    export GITFLOW_CONFIG_DIR="$TEST_ROOT/etc/gitflow"
    export GITFLOW_USER_CONFIG_DIR="$TEST_ROOT/.config/gitflow"
    export PATH="$TEST_ROOT/usr/bin:$PATH"
    
    echo "✅ Test environment set up at: $TEST_ROOT"
    return 0
}

verify_build_requirements() {
    echo "🔄 Verifying build requirements..."
    
    # Check required commands
    local required_commands=(jq git bash)
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "❌ Required command not found: $cmd"
            echo "Please install missing dependencies"
            return 1
        fi
    done
    
    # Check required directories
    local required_dirs=(
        "usr/share/gitflow/lib"
        "usr/share/gitflow/plugins"
        "usr/bin"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$PROJECT_ROOT/$dir" ]; then
            echo "❌ Required directory not found: $dir"
            return 1
        fi
    done
    
    echo "✅ All build requirements met"
    return 0
}

# Run test suite
run_tests() {
    echo "🔄 Running test suite..."
    
    # Set up test environment
    setup_test_environment || return 1
    
    if ! bash "$GITFLOW_WORK_DIR/tests/core/suite.sh"; then
        echo "❌ Tests failed - aborting build"
        return 1
    fi
    
    echo "✅ All tests passed"
    return 0
}

# Main build process
main() {
    # Add requirement check first
    verify_build_requirements || exit 1
    
    # Set initial permissions
    set_initial_permissions

    # Create build directory
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
    cd "$BUILD_DIR"

    # Clean any previous build artifacts
    rm -rf debian/gitflow/
    rm -f ../*.buildinfo ../*.changes

    # Ensure we have required packages
    if ! dpkg -l | grep -q "^ii  debhelper "; then
        echo "Installing required packages..."
        sudo apt-get update
        sudo apt-get install -y build-essential debhelper devscripts
    fi

    # Create package structure
    mkdir -p debian/gitflow/usr/share/gitflow/{lib,plugins/{official,metadata}}
    mkdir -p debian/gitflow/usr/bin
    mkdir -p debian/gitflow/etc/gitflow

    # Initialize plugin registry
    REGISTRY_FILE="debian/gitflow/usr/share/gitflow/plugins/metadata/plugins.json"
    mkdir -p "$(dirname "$REGISTRY_FILE")"
    echo '{"plugins":{}}' > "$REGISTRY_FILE"
    chmod 644 "$REGISTRY_FILE"

    # Copy files
    echo "🔄 Copying files..."
    cp -r usr/share/gitflow/* debian/gitflow/usr/share/gitflow/
    cp usr/bin/gitflow debian/gitflow/usr/bin/

    # Set permissions
    echo "🔄 Setting permissions..."
    find debian/gitflow/usr/share/gitflow -type f -name "*.sh" -exec chmod 755 {} \;
    find debian/gitflow/usr/share/gitflow -type f ! -name "*.sh" -exec chmod 644 {} \;
    find debian/gitflow/usr/share/gitflow -type d -exec chmod 755 {} \;
    chmod 755 debian/gitflow/usr/bin/gitflow

    # Remove debian/compat if it exists (we're using debhelper-compat)
    rm -f debian/compat

    # Ensure debian/rules is executable
    chmod 755 debian/rules

    # Create etc/gitflow directory and default files
    mkdir -p etc/gitflow
    touch etc/gitflow/config.template
    chmod 644 etc/gitflow/config.template

    # Build package
    echo "🔄 Building package..."
    if ! dpkg-buildpackage -us -uc; then
        echo "❌ Package build failed"
        exit 1
    fi

    # Copy package to original project directory
    mkdir -p "$PROJECT_ROOT/build"
    cp -f "../gitflow_"*".deb" "$PROJECT_ROOT/build/"

    # Cleanup
    rm -f ../*.buildinfo ../*.changes

    echo "✅ Build completed successfully"
}

main "$@"