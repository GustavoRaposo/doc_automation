#!/bin/bash

source "$GITFLOW_LIB_DIR/constants.sh"
source "$GITFLOW_LIB_DIR/utils.sh"

# Create version control directory
mkdir -p "$(dirname $GITFLOW_VERSION_FILE)"

get_version() {
   if [ ! -f "$GITFLOW_VERSION_FILE" ]; then
       echo "v0.0.0.0"
       return
   fi
   cat "$GITFLOW_VERSION_FILE"
}

get_package_version() {
   if [ ! -f "$GITFLOW_VERSION_FILE" ]; then
       echo "v0.0.0.0"
       return
   fi
   cat "$GITFLOW_VERSION_FILE"
}

update_debian_changelog() {
   local new_version=$1
   local commit_msg=$2
   local version_type=$3
   local temp_file=$(mktemp)
   local date=$(date -R)
   local maintainer="Guilherme Davedovicz <guilherme.davedovicz@brainrobot.com.br>"
   local debian_version=$(echo "${new_version#v}" | awk -F. '{print $1"."$2"."$3}')

   cat >"$temp_file" <<EOF
gitflow ($debian_version) jammy; urgency=medium

 * ${commit_msg:-Package version update}
 * Version update type: $version_type
EOF

   [ -n "$4" ] && echo "  * Changes: $4" >>"$temp_file"

   cat >>"$temp_file" <<EOF

-- $maintainer  $date

EOF

   [ -f debian/changelog ] && cat debian/changelog >>"$temp_file"

   mkdir -p debian
   mv "$temp_file" debian/changelog

   if [ -f debian/files ]; then
       sed -i "s/gitflow_[0-9.]*_/gitflow_${debian_version}_/g" debian/files
   else
       echo "gitflow_${debian_version}_all.deb utils optional" >debian/files
   fi

   log_success "Updated debian/changelog for version $debian_version"
}