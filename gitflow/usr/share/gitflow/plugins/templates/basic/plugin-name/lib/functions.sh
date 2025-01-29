#!/bin/bash

source "$GITFLOW_LIB_DIR/utils.sh"

PLUGIN_TMP_DIR="$(dirname "$0")/../tmp"

clean_tmp_files() {
    find "$PLUGIN_TMP_DIR" -type f -mmin +60 -delete
}

create_tmp_file() {
    local prefix="$1"
    local tmp_file="$PLUGIN_TMP_DIR/${prefix}_$(date +%s)_$RANDOM"
    touch "$tmp_file"
    echo "$tmp_file"
}