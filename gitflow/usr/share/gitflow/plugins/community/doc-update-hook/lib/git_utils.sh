#!/bin/bash

get_repo_info() {
    local remote_url=$(git config --get remote.origin.url || echo "default_repo")
    if [ -n "$remote_url" ] && [ "$remote_url" != "default_repo" ]; then
        echo $(basename -s .git "$remote_url")
    else
        echo "api_reference"
    fi
}

get_commit_info() {
    local info=()
    info[0]=$(git rev-parse HEAD 2>/dev/null || echo "")
    
    if git rev-parse HEAD^1 >/dev/null 2>&1; then
        info[1]=$(git rev-parse HEAD^1)
    else
        info[1]=$(git hash-object -t tree /dev/null)
    fi
    
    info[2]=$(git log -1 --pretty=%B)
    info[3]=$(git log -1 --pretty=format:'%an')
    info[4]=$(git log -1 --pretty=format:'%ae')
    info[5]=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "master")
    info[6]=$(git log -1 --pretty=format:'%ct')
    
    echo "${info[@]}"
}