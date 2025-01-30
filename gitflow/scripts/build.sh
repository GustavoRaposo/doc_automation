#!/bin/bash

# Determine script and project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_ROOT="$(readlink -f "${PROJECT_ROOT}/debian/gitflow")"
BUILD_DIR="$(readlink -f "${PROJECT_ROOT}/build")"

setup_build_paths() {
    # Ensure build paths are consistent
    export GITFLOW_BUILD_DIR="$PACKAGE_ROOT"
    export GITFLOW_BUILD_SYSTEM_DIR="$PACKAGE_ROOT/usr/share/gitflow"
    export GITFLOW_BUILD_LIB_DIR="$GITFLOW_BUILD_SYSTEM_DIR/lib"
    export GITFLOW_BUILD_PLUGINS_DIR="$GITFLOW_BUILD_SYSTEM_DIR/plugins"
    export GITFLOW_BUILD_CONFIG_DIR="$GITFLOW_BUILD_DIR/etc/gitflow"
}

# Safety check function for directory operations
verify_build_directory() {
    local dir="$1"
    
    # Ensure we're not in PROJECT_ROOT
    if [ "$(readlink -f "$dir")" = "$(readlink -f "$PROJECT_ROOT")" ]; then
        echo "❌ Safety check failed: Would not delete project directory"
        return 1
    fi
    
    # Ensure we're in a build directory
    if [[ ! "$dir" =~ ^/tmp/gitflow-(work|build) ]]; then
        echo "❌ Safety check failed: Not a valid build directory"
        return 1
    fi
    
    return 0
}

# Function to safely clean build artifacts
clean_build_artifacts() {
    local build_dir="$1"
    
    if [ -d "$build_dir/debian/gitflow" ]; then
        echo "Cleaning previous build artifacts..."
        rm -rf "$build_dir/debian/gitflow"
    fi
    
    # Clean only build-related files
    if [ -d "$build_dir/.." ]; then
        find "$build_dir/.." -maxdepth 1 -type f \( -name "*.buildinfo" -o -name "*.changes" \) -delete
    fi
}

# Set correct permissions for all files before any operations
set_initial_permissions() {
    echo "🔄 Setting up working directory..."
    
    # Create temporary working directory outside shared folder
    WORK_DIR="/tmp/gitflow-work-$$"
    mkdir -p "$WORK_DIR"
    
    # Verify directory before setting trap
    if ! verify_build_directory "$WORK_DIR"; then
        exit 1
    fi
    
    # Set cleanup trap after verification
    trap 'if verify_build_directory "$WORK_DIR"; then rm -rf "$WORK_DIR"; fi' EXIT
    
    # Copy files to working directory with preserved permissions
    echo "Copying files to working directory..."
    rsync -a --chmod=u=rwX,g=rX,o=rX "$PROJECT_ROOT/"* "$WORK_DIR/"
    
    # Set explicit permissions for critical files
    find "$WORK_DIR" -type f -name "*.sh" -exec chmod 755 {} \;
    find "$WORK_DIR" -type d -exec chmod 755 {} \;
    chmod 755 "$WORK_DIR/usr/bin/gitflow"
    
    # Ensure plugin directories are properly configured
    mkdir -p "$WORK_DIR/usr/share/gitflow/plugins/"{official,community,templates/basic}
    chmod -R 755 "$WORK_DIR/usr/share/gitflow/plugins"
    
    # Export working directory for other functions
    export GITFLOW_WORK_DIR="$WORK_DIR"
    
    echo "✅ Working directory set up at: $WORK_DIR"
}

# Verify test environment
verify_test_environment() {
    echo "🔄 Verifying test environment..."
    
    # Check for required commands
    local required_commands=(jq git bash mktemp)
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "❌ Required command not found: $cmd"
            return 1
        fi
    done
    
    # Check for required directories
    if [ -z "$GITFLOW_WORK_DIR" ]; then
        echo "❌ GITFLOW_WORK_DIR not set"
        return 1
    fi
    
    # Verify library files exist
    local required_libs=(constants.sh utils.sh config.sh hook-management.sh git.sh)
    for lib in "${required_libs[@]}"; do
        if [ ! -f "$GITFLOW_WORK_DIR/usr/share/gitflow/lib/$lib" ]; then
            echo "❌ Required library not found: $lib"
            return 1
        fi
    done
    
    echo "✅ Test environment verified"
    return 0
}

# Verify build requirements
verify_build_requirements() {
    echo "🔄 Verifying build requirements..."
    
    # Check required commands
    local required_commands=(jq git bash dpkg-buildpackage)
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
        "debian"
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
    
    # Verify and set up test environment
    if ! verify_test_environment; then
        return 1
    fi
        
    if [ ! -f "$GITFLOW_WORK_DIR/tests/core/suite.sh" ]; then
        echo "❌ Test suite not found"
        return 1
    fi
    
    if ! bash "$GITFLOW_WORK_DIR/tests/core/suite.sh"; then
        echo "❌ Tests failed - aborting build"
        return 1
    fi
    
    echo "✅ All tests passed"
    return 0
}

# Create Debian package structure
create_package_structure() {
    local build_dir="$1"
    
    echo "🔄 Creating package structure..."
    
    # Create required directories
    local dirs=(
        "debian/gitflow/usr/share/gitflow/lib"
        "debian/gitflow/usr/share/gitflow/plugins/official"
        "debian/gitflow/usr/share/gitflow/plugins/metadata"
        "debian/gitflow/usr/share/gitflow/plugins/community"
        "debian/gitflow/usr/bin"
        "debian/gitflow/etc/gitflow"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$build_dir/$dir"
        chmod 755 "$build_dir/$dir"
    done
    
    # Initialize plugin registry
    local registry_file="$build_dir/debian/gitflow/usr/share/gitflow/plugins/metadata/plugins.json"
    echo '{"plugins":{}}' > "$registry_file"
    chmod 644 "$registry_file"
    
    return 0
}

# Copy files to package
copy_package_files() {
    local build_dir="$1"
    
    echo "🔄 Copying package files..."
    
    # Copy with correct paths
    cp -r "$build_dir/usr/share/gitflow/lib/"* "$build_dir/debian/gitflow/usr/share/gitflow/lib/"
    cp -r "$build_dir/usr/share/gitflow/plugins/official" "$build_dir/debian/gitflow/usr/share/gitflow/plugins/"
    cp -r "$build_dir/usr/share/gitflow/plugins/community" "$build_dir/debian/gitflow/usr/share/gitflow/plugins/"
    cp -r "$build_dir/usr/share/gitflow/plugins/templates" "$build_dir/debian/gitflow/usr/share/gitflow/plugins/"
    cp "$build_dir/usr/bin/gitflow" "$build_dir/debian/gitflow/usr/bin/"
    
    # Set correct permissions
    find "$build_dir/debian/gitflow" -type f -name "*.sh" -exec chmod 755 {} \;
    find "$build_dir/debian/gitflow" -type f ! -name "*.sh" -exec chmod 644 {} \;
    find "$build_dir/debian/gitflow" -type d -exec chmod 755 {} \;
    chmod 755 "$build_dir/debian/gitflow/usr/bin/gitflow"
    
    return 0
}

# Main build process
main() {
    # Verify build requirements first
    if ! verify_build_requirements; then
        exit 1
    fi
    
    # Set up initial permissions and working directory
    set_initial_permissions
    
    # Create build directory
    BUILD_DIR="/tmp/gitflow-build-$$"
    mkdir -p "$BUILD_DIR"
    
    # Verify directory before setting trap
    if ! verify_build_directory "$BUILD_DIR"; then
        exit 1
    fi
    
    # Set cleanup trap after verification
    trap 'if verify_build_directory "$BUILD_DIR"; then rm -rf "$BUILD_DIR"; fi' EXIT
    
    # Run tests
    if ! run_tests; then
        exit 1
    fi
    
    # Copy project files to build directory
    echo "Copying project files to build directory..."
    cp -r "$GITFLOW_WORK_DIR/"* "$BUILD_DIR/"
    cd "$BUILD_DIR"
    
    # Clean build artifacts safely
    clean_build_artifacts "$BUILD_DIR"
    
    # Ensure build dependencies
    if ! dpkg -l | grep -q "^ii  debhelper "; then
        echo "Installing required packages..."
        sudo apt-get update
        sudo apt-get install -y build-essential debhelper devscripts
    fi
    
    # Create package structure and copy files
    if ! create_package_structure "$BUILD_DIR"; then
        echo "❌ Failed to create package structure"
        exit 1
    fi
    
    if ! copy_package_files "$BUILD_DIR"; then
        echo "❌ Failed to copy package files"
        exit 1
    fi
    
    # Ensure debian/rules is executable
    chmod 755 debian/rules
    
    # Create config template
    mkdir -p etc/gitflow
    touch etc/gitflow/config.template
    chmod 644 etc/gitflow/config.template
    
    # Build package
    echo "🔄 Building package..."
    if ! dpkg-buildpackage -us -uc; then
        echo "❌ Package build failed"
        exit 1
    fi
    
    # Copy package to output directory
    mkdir -p "$PROJECT_ROOT/build"
    if ! cp -f "../gitflow_"*".deb" "$PROJECT_ROOT/build/"; then
        echo "❌ Failed to copy package to output directory"
        exit 1
    fi
    
    echo "✅ Build completed successfully"
}

# Execute main function
main "$@"