#!/bin/bash
set -e

# Determine script and project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/debian"

# Update path to match the build structure
VERSION_FILE="$BUILD_ROOT/usr/share/gitflow/plugins/official/version-update-hook/files/.version"
VERSION_DIR="$(dirname "$VERSION_FILE")"

# Ensure version directory exists
mkdir -p "$VERSION_DIR"

# Initialize version file if it doesn't exist
if [ ! -f "$VERSION_FILE" ]; then
    echo "v0.0.0.0" > "$VERSION_FILE"
    chmod 644 "$VERSION_FILE"
fi

convert_version() {
    local version=$1
    echo "${version#v}" | awk -F. '{print $1"."$2"."$3}'
}

update_changelog() {
    local new_version=$1
    local temp_file=$(mktemp)
    local date=$(date -R)
    local maintainer="GitFlow Maintainers <maintainers@gitflow.org>"

    cat > "$temp_file" <<EOF
gitflow ($new_version) jammy; urgency=medium

  * Automated version sync from .version file
EOF

    [ -n "$4" ] && echo "  * Changes: $4" >> "$temp_file"
    cat >> "$temp_file" <<EOF

 -- $maintainer  $date

EOF

    [ -f debian/changelog ] && cat debian/changelog >> "$temp_file"
    mkdir -p debian
    mv "$temp_file" debian/changelog
}

update_files() {
    echo "gitflow_${1}_all.deb utils optional" > debian/files
}

main() {
    VERSION_FILE_CONTENT=$(cat "$VERSION_FILE")
    PACKAGE_VERSION=$(convert_version "$VERSION_FILE_CONTENT")

    update_changelog "$PACKAGE_VERSION"
    update_files "$PACKAGE_VERSION"
    echo "PACKAGE_VERSION=$PACKAGE_VERSION" > .package_version
    
    echo "✅ Version sync completed successfully"
}

main "$@"