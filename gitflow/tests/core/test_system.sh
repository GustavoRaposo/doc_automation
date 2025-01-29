#!/bin/bash
set -e

# Determine script and project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source dependencies
source "$PROJECT_ROOT/usr/share/gitflow/lib/utils.sh"
source "$PROJECT_ROOT/usr/share/gitflow/lib/constants.sh"

# Test library loading
test_library_loading() {
    echo "Testing library loading..."
    local failed=0
    
    local required_libs=(
        "constants.sh"
        "utils.sh"
        "gitflow-version-control.sh"
        "config.sh"
        "hook-management.sh"
        "git.sh"
    )
    
    for lib in "${required_libs[@]}"; do
        if [ ! -f "$PROJECT_ROOT/usr/share/gitflow/lib/$lib" ]; then
            log_error "Required library not found: $lib"
            failed=1
        else
            # Try sourcing the library
            if ! source "$PROJECT_ROOT/usr/share/gitflow/lib/$lib" 2>/dev/null; then
                log_error "Failed to source library: $lib"
                failed=1
            fi
        fi
    done
    
    return $failed
}

# Test directory structure
test_directory_structure() {
    echo "Testing directory structure..."
    local failed=0
    
    local required_dirs=(
        "usr/share/gitflow"
        "usr/share/gitflow/lib"
        "usr/share/gitflow/plugins"
        "usr/share/gitflow/plugins/official"
        "usr/share/gitflow/plugins/community"
        "usr/share/gitflow/plugins/templates"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$PROJECT_ROOT/$dir" ]; then
            log_error "Required directory not found: $dir"
            failed=1
        fi
    done
    
    return $failed
}

# Test file permissions
test_file_permissions() {
    echo "Testing file permissions..."
    local failed=0
    
    # Test executable files
    local executables=(
        "usr/bin/gitflow"
        "usr/share/gitflow/lib/utils.sh"
        "usr/share/gitflow/lib/constants.sh"
        "usr/share/gitflow/lib/git.sh"
        "usr/share/gitflow/lib/gitflow-version-control.sh"
        "usr/share/gitflow/lib/hook-management.sh"
        "usr/share/gitflow/lib/config.sh"
    )
    
    for file in "${executables[@]}"; do
        if [ ! -x "$PROJECT_ROOT/$file" ]; then
            log_error "File not executable: $file"
            failed=1
        fi
    done
    
    # Test directory permissions
    find "$PROJECT_ROOT/usr/share/gitflow" -type d -print0 | while IFS= read -r -d '' dir; do
        if [ ! -x "$dir" ]; then
            log_error "Directory not executable: $dir"
            failed=1
        fi
    done
    
    return $failed
}

# Test command line interface
test_cli() {
    echo "Testing command line interface..."
    local failed=0
    
    # Test help command
    if ! gitflow --help | grep -q "Usage:"; then
        log_error "Help command failed"
        failed=1
    fi
    
    # Test version command
    if ! gitflow --version | grep -q "gitflow version"; then
        log_error "Version command failed"
        failed=1
    fi
    
    # Test invalid command
    if gitflow --invalid-command 2>&1 | grep -q "Unknown option"; then
        :  # Expected behavior
    else
        log_error "Invalid command handling failed"
        failed=1
    fi
    
    return $failed
}

# Test environment variables
test_environment() {
    echo "Testing environment variables..."
    local failed=0
    
    # Test required environment variables
    local required_vars=(
        "GITFLOW_SYSTEM_DIR"
        "GITFLOW_LIB_DIR"
        "GITFLOW_PLUGINS_DIR"
        "GITFLOW_CONFIG_DIR"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_error "Required environment variable not set: $var"
            failed=1
        fi
    done
    
    return $failed
}

# Run all tests
run_system_tests() {
    local failed=0
    
    test_library_loading || failed=1
    test_directory_structure || failed=1
    test_file_permissions || failed=1
    test_cli || failed=1
    test_environment || failed=1
    
    if [ $failed -eq 0 ]; then
        log_success "All system tests passed"
    else
        log_error "Some system tests failed"
    fi
    
    return $failed
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_system_tests
fi