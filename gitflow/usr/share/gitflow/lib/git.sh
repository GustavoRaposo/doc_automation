#!/bin/bash

source "$GITFLOW_LIB_DIR/constants.sh"
source "$GITFLOW_LIB_DIR/utils.sh"

is_main_branch() {
   local current_branch=$1
   local main_branches=("main" "master")
   for main in "${main_branches[@]}"; do
       if [ "$current_branch" = "$main" ]; then
           return 0
       fi
   done
   return 1
}

get_current_branch() {
   local branch
   if ! branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null); then
       log_error "Failed to get current branch"
       return 1
   fi
   echo "$branch"
}

get_previous_branch() {
   local prev_branch_file=".git/prev-branch" 
   if [ -f "$prev_branch_file" ]; then
       cat "$prev_branch_file"
   else
       echo ""
   fi
}

save_current_branch() {
   local branch=$(get_current_branch)
   echo "$branch" > ".git/prev-branch"
}