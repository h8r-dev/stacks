#! /usr/bin/env bash

set -ex

WORKING_DIR=/scaffold

[ ! -d $WORKING_DIR ] && mkdir -p $WORKING_DIR

# Get template name
tempalteArr=(${APP_TEMPLATE//// })
TEMPLATE_NAME=${tempalteArr[1]}

clone_from_git_repo() {
  clone_url=$1
  git clone $clone_url
  mv $TEMPLATE_NAME $APP_NAME
  rm -rf "$APP_NAME/.git" # Clear history commits
}

download_package() {
  package_url=$1
  package_name="$APP_TEMPLATE.tar.gz"
  wget $package_url
  tar -zxf $package_name
  rm $package_name
  mv $TEMPLATE_NAME $APP_NAME
}

# Pull template files
cd $WORKING_DIR
TEMPLATE_URL="$REGISTRY/$APP_TEMPLATE"

if [[ $TEMPLATE_URL == https://github.com* ]]; then
  clone_from_git_repo "$TEMPLATE_URL.git"
else
  download_package "$TEMPLATE_URL.tar.gz"
fi

echo "Download source code template successfully!"
