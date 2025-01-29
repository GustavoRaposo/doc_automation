#!/bin/bash
set -e

# Determine script and project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/debian"

echo "Starting build process..."
echo "Project root: $PROJECT_ROOT"
echo "Build root: $BUILD_ROOT"

# Set up debian directory structure and configuration
echo "🔄 Setting up Debian build configuration..."
bash "$SCRIPT_DIR/setup-debian.sh"

# Verify debian/rules is executable
if [ ! -x "$PROJECT_ROOT/debian/rules" ]; then
    echo "Fixing debian/rules permissions..."
    chmod 755 "$PROJECT_ROOT/debian/rules"
fi

# Create Debian package structure
echo "🔄 Creating package directory structure..."
mkdir -p "$BUILD_ROOT"/usr/share/gitflow/{lib,plugins/{official,community,templates/basic/{events,files},metadata}}
mkdir -p "$BUILD_ROOT"/usr/bin
mkdir -p "$BUILD_ROOT"/etc/gitflow

# Initialize version file
VERSION_DIR="$BUILD_ROOT/usr/share/gitflow/plugins/official/version-update-hook/files"
VERSION_FILE="$VERSION_DIR/.version"
mkdir -p "$VERSION_DIR"
[ ! -f "$VERSION_FILE" ] && echo "v0.0.0.0" > "$VERSION_FILE"
chmod 644 "$VERSION_FILE"

# Initialize plugin registry
REGISTRY_FILE="$BUILD_ROOT/usr/share/gitflow/plugins/metadata/plugins.json"
mkdir -p "$(dirname "$REGISTRY_FILE")"
echo '{"plugins":{}}' > "$REGISTRY_FILE"
chmod 644 "$REGISTRY_FILE"

# Copy main executable
echo "🔄 Copying main executable..."
cp -p usr/bin/gitflow "$BUILD_ROOT/usr/bin/"
chmod 755 "$BUILD_ROOT/usr/bin/gitflow"

# Copy library files
echo "🔄 Copying library files..."
if [ -d "usr/share/gitflow/lib" ]; then
    mkdir -p "$BUILD_ROOT/usr/share/gitflow/lib"
    cp -r usr/share/gitflow/lib/* "$BUILD_ROOT/usr/share/gitflow/lib/"
fi

# Copy plugins (Modified Section)
echo "🔄 Copying plugins..."
for plugin_type in official; do
    SRC_DIR="usr/share/gitflow/plugins/$plugin_type"
    if [ -d "$SRC_DIR" ]; then
        mkdir -p "$BUILD_ROOT/usr/share/gitflow/plugins/$plugin_type"
        cp -r "$SRC_DIR"/* "$BUILD_ROOT/usr/share/gitflow/plugins/$plugin_type/"
    fi
done

# Set file permissions
echo "🔄 Setting file permissions..."
find "$BUILD_ROOT/usr/share/gitflow" -type f -name "*.sh" -exec chmod 755 {} \;
find "$BUILD_ROOT/usr/share/gitflow" -type f ! -name "*.sh" -exec chmod 644 {} \;
find "$BUILD_ROOT/usr/share/gitflow" -type d -exec chmod 755 {} \;

echo "🔄 Syncing version..."
bash "$SCRIPT_DIR/version-sync.sh"

# Source package version if exists
[ -f .package_version ] && source .package_version

# Verify debian/rules is still executable
chmod 755 "$PROJECT_ROOT/debian/rules"
ls -la "$PROJECT_ROOT/debian/rules"

echo "🔄 Building Debian package..."
if ! dpkg-buildpackage -us -uc; then
    echo "❌ Package build failed"
    exit 1
fi

# Create build directory and move package
mkdir -p build/
if ! mv "../gitflow_${PACKAGE_VERSION:-0.0.1}_all.deb" build/; then
    echo "❌ Failed to move .deb file"
    exit 1
fi

# Cleanup
rm -f ../*.buildinfo ../*.changes
rm -f .package_version

echo "✅ Build completed successfully"