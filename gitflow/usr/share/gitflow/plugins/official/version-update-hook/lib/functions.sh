#!/bin/bash

source "$GITFLOW_LIB_DIR/utils.sh"

# Simplified temporary directory handling
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_TMP_DIR="$PLUGIN_DIR/tmp"
VERSION_DIR=".git/version-control"
VERSION_FILE="$VERSION_DIR/.version"
BRANCH_VERSIONS_FILE="$VERSION_DIR/.branch_versions"

# Ensure tmp directory exists
[ ! -d "$PLUGIN_TMP_DIR" ] && mkdir -p "$PLUGIN_TMP_DIR"

# Version Control Functions
get_version() {
    local version=$(cat "$VERSION_FILE" 2>/dev/null || echo "v0.0.0.0")
    if [[ ! $version =~ ^v[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        version="v0.0.0.0"
        echo "$version" > "$VERSION_FILE"
    fi
    echo "$version"
}

extract_version_components() {
    local version=${1#v}
    local a b c d
    IFS='.' read -r a b c d <<< "$version"
    [[ $a =~ ^[0-9]+$ ]] || a=0
    [[ $b =~ ^[0-9]+$ ]] || b=0
    [[ $c =~ ^[0-9]+$ ]] || c=0
    [[ $d =~ ^[0-9]+$ ]] || d=0
    printf "%d %d %d %d" "$a" "$b" "$c" "$d"
}

construct_version() {
    printf "v%d.%d.%d.%d" "${1:-0}" "${2:-0}" "${3:-0}" "${4:-0}"
}

init_version() {
    if [ ! -f "$VERSION_FILE" ]; then
        echo "v0.0.0.0" > "$VERSION_FILE"
        chmod 644 "$VERSION_FILE"
        git add "$VERSION_FILE" 2>/dev/null || true
    fi

    if [ ! -f "$BRANCH_VERSIONS_FILE" ]; then
        echo "{}" > "$BRANCH_VERSIONS_FILE"
        chmod 644 "$BRANCH_VERSIONS_FILE"
        git add "$BRANCH_VERSIONS_FILE" 2>/dev/null || true
    fi
}

get_branch_version() {
    local branch=$1
    if [ -f "$BRANCH_VERSIONS_FILE" ]; then
        local versions=$(cat "$BRANCH_VERSIONS_FILE")
        if [[ $versions == *"\"$branch\""* ]]; then
            echo "$versions" | grep -o "\"$branch\":\"\([0-9]*\.[0-9]*\)\"" | cut -d'"' -f4
            return 0
        fi
    fi
    echo "0.0"
}

save_branch_version() {
    local branch=$1
    local version=$2
    local versions="{}"
    
    [[ ! $version =~ ^[0-9]+\.[0-9]+$ ]] && version="0.0"
    [ -f "$BRANCH_VERSIONS_FILE" ] && versions=$(cat "$BRANCH_VERSIONS_FILE")
    
    versions=$(echo "$versions" | sed "s|\"$branch\":\"\([0-9]*\.[0-9]*\)\",\?||g")
    versions=$(echo "$versions" | sed 's/,}/}/g' | sed 's/,\s*,/,/g')
    [ -z "$versions" ] && versions="{}"
    
    if [ "$versions" == "{}" ]; then
        versions="{\"$branch\":\"$version\"}"
    else
        versions=${versions%\}}
        [[ $versions != *"{"* ]] && versions="{$versions"
        versions="$versions,\"$branch\":\"$version\"}"
    fi
    
    echo "$versions" > "$BRANCH_VERSIONS_FILE"
    git add "$BRANCH_VERSIONS_FILE" 2>/dev/null || true
}

set_version() {
    local new_version=$1
    echo "$new_version" > "$VERSION_FILE"
    chmod 644 "$VERSION_FILE"
}

handle_major_version() {
    local message=$(git log -1 --format=%B)
    if [[ $message == *"MAJOR:"* ]]; then
        local current_version=$(get_version)
        read -r v a b c d <<< "$(extract_version_components "$current_version")"
        set_version "$(construct_version "$((a + 1))" "0" "0" "0")"
    fi
}

handle_manual_override() {
    local message=$(git log -1 --format=%B)
    if [[ $message =~ VERSION=v[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ]]; then
        local new_version=${BASH_REMATCH[0]#VERSION=}
        set_version "$new_version"
    fi
}

handle_merge_to_principal() {
    local current_version=$(get_version)
    read -r v a b c d <<< "$(extract_version_components "$current_version")"

    local merge_bases=($(git rev-list --parents HEAD | grep " .*" | tail -n 1))
    unset 'merge_bases[0]'

    local highest_c=0
    local highest_d=0

    for commit in "${merge_bases[@]}"; do
        local branch_name=$(git name-rev --name-only "$commit" 2>/dev/null | sed 's/\^0$//' | sed 's/~.*//')
        [[ $branch_name == "master" || $branch_name == "main" ]] && continue

        local branch_version=$(get_branch_version "$branch_name")
        read -r branch_c branch_d <<< "${branch_version//./ }"

        ((branch_c > highest_c)) && highest_c=$branch_c
        ((branch_d > highest_d)) && highest_d=$branch_d
    done

    b=$((b + 1))
    ((highest_c > c)) && c=$highest_c
    ((highest_d > d)) && d=$highest_d

    set_version "$(construct_version "$a" "$b" "$c" "$d")"
}

handle_rebase() {
    local current_branch=$1
    local target_branch=$2
    local current_version=$(get_version)
    read -r v a b c d <<< "$(extract_version_components "$current_version")"
    local branch_version=$(get_branch_version "$current_branch")
    read -r branch_c branch_d <<< "${branch_version//./ }"

    if [[ $target_branch == "master" || $target_branch == "main" ]]; then
        local target_version=$(get_version)
        read -r tv ta tb tc td <<< "$(extract_version_components "$target_version")"
        set_version "$(construct_version "$ta" "$tb" "$branch_c" "$branch_d")"
    else
        local target_branch_version=$(get_branch_version "$target_branch")
        read -r target_c target_d <<< "${target_branch_version//./ }"
        branch_c=$((target_c + 1))
        branch_d=0
        set_version "$(construct_version "$a" "$b" "$branch_c" "$branch_d")"
    fi

    save_branch_version "$current_branch" "$branch_c.$branch_d"
}

init_fork() {
    # Garantir que o diretório .git existe
    if [ ! -d ".git" ]; then
        git init
    fi
    
    # Criar diretório de controle de versão
    mkdir -p "$VERSION_DIR"
    
    # Reset versão para 0.0.0.0
    echo "v0.0.0.0" > "$VERSION_FILE"
    chmod 644 "$VERSION_FILE"
    
    # Reset branch versions
    echo "{}" > "$BRANCH_VERSIONS_FILE"
    chmod 644 "$BRANCH_VERSIONS_FILE"
    
    # Adicionar arquivos ao git
    git add "$VERSION_FILE" "$BRANCH_VERSIONS_FILE" 2>/dev/null || true
    
    log_success "Fork initialized with version v0.0.0.0"
    return 0
}

increment_major() {
    # Garantir que o diretório existe
    mkdir -p "$VERSION_DIR"
    
    local current_version=$(get_version)
    local v a b c d
    
    # Extrair os componentes da versão atual
    local version_numbers=${current_version#v}
    IFS='.' read -r a b c d <<< "$version_numbers"
    
    # Garantir que os valores são numéricos
    [[ $a =~ ^[0-9]+$ ]] || a=0
    [[ $b =~ ^[0-9]+$ ]] || b=0
    [[ $c =~ ^[0-9]+$ ]] || c=0
    [[ $d =~ ^[0-9]+$ ]] || d=0
    
    # Incrementar versão major e resetar outros componentes
    a=$((a + 1))
    b=0
    c=0
    d=0
    
    local new_version="v$a.$b.$c.$d"
    set_version "$new_version"
    log_success "Incremented major version to $new_version"
}

tag_release() {
    local version=$1
    local release_name=$2
    
    # Validate version format
    if [[ ! $version =~ ^v[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Invalid version format. Must be vA.B.C.D"
        return 1
    fi
    
    # Create and push tag
    push_tag "$version" "Release: $release_name"
}

handle_version_bump() {
    local current_branch=$1
    local current_version=$(get_version)
    read -r a b c d <<< "$(extract_version_components "$current_version")"

    # Handle rebase
    if [ -f ".git/rebase-merge/onto" ]; then
        local target_branch=$(git name-rev --name-only $(cat .git/rebase-merge/onto))
        handle_rebase "$current_branch" "$target_branch"
        return
    fi

    # Handle principal branch
    if [[ $current_branch == "master" || $current_branch == "main" ]]; then
        if git rev-parse -q --verify MERGE_HEAD >/dev/null; then
            handle_merge_to_principal
            return
        fi
        
        d=$((d + 1))
        set_version "$(construct_version "$a" "$b" "$c" "$d")"
        return
    fi

    # Handle feature branches
    local branch_version=$(get_branch_version "$current_branch")
    read -r branch_c branch_d <<< "${branch_version//./ }"
    
    # Ensure branch components are numbers
    [[ $branch_c =~ ^[0-9]+$ ]] || branch_c=0
    [[ $branch_d =~ ^[0-9]+$ ]] || branch_d=0

    # Check for new branch
    if ! git rev-parse --verify "origin/$current_branch" >/dev/null 2>&1 || \
       ! git rev-parse --verify "$current_branch@{upstream}" >/dev/null 2>&1 || \
       [ "$branch_version" == "0.0" ]; then
        
        # Get parent branch
        local parent_branch=$(git rev-parse --abbrev-ref "$current_branch@{upstream}" 2>/dev/null | sed 's/origin\///')
        
        if [ -z "$parent_branch" ]; then
            for main in "master" "main"; do
                git rev-parse --verify "$main" >/dev/null 2>&1 && parent_branch="$main" && break
            done
        fi

        [ -z "$parent_branch" ] && parent_branch=$(git show-branch -a 2>/dev/null | 
            grep '\*' | 
            grep -v "$(git rev-parse --abbrev-ref HEAD)" | 
            head -n1 | 
            sed 's/.*\[\(.*\)\].*/\1/' | 
            sed 's/[\^~].*//')

        local parent_version=$(get_branch_version "$parent_branch")
        read -r parent_c parent_d <<< "${parent_version//./ }"
        
        # Ensure parent components are numbers
        [[ $parent_c =~ ^[0-9]+$ ]] || parent_c=0
        [[ $parent_d =~ ^[0-9]+$ ]] || parent_d=0
        
        branch_c=$((parent_c + 1))
        branch_d=0
    else
        branch_d=$((branch_d + 1))
    fi

    save_branch_version "$current_branch" "${branch_c}.${branch_d}"
    set_version "$(construct_version "$a" "$b" "$branch_c" "$branch_d")"
}

push_tag() {
    local tag=$1
    local msg="${2:-Version update}"
    local push_error_file="$PLUGIN_TMP_DIR/push_error_$tag"

    if ! git tag -a "$tag" -m "$msg" 2>"$PLUGIN_TMP_DIR/tag_error"; then
        log_error "Failed to create tag: $(cat "$PLUGIN_TMP_DIR/tag_error")"
        rm -f "$PLUGIN_TMP_DIR/tag_error"
        return 1
    fi

    for i in {1..3}; do
        if git push origin "$tag" 2>"$push_error_file"; then
            log_success "Tag $tag pushed to remote"
            rm -f "$push_error_file"
            return 0
        else
            log_error "Push attempt $i failed: $(cat "$push_error_file")"
            sleep 2
        fi
    done

    log_error "Failed to push tag $tag after 3 attempts. Last error: $(cat "$push_error_file")"
    rm -f "$push_error_file"
    return 1
}