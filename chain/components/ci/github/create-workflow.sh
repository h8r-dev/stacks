#! /usr/bin/env bash

TARGET_DIR=/scaffold/$REPO_NAME/.github/workflows

# Create github workflow dir
mkdir -p $TARGET_DIR

# Copy docker-publish.yaml file into target dir
mv $TEMPLATE_DIR/docker-publish.yaml $TARGET_DIR/

ACTION_FILE=$TARGET_DIR/docker-publish.yaml

# Render docker-publish.yaml file with data provided
yq -i '
  .env.ORG = "'$ORGANIZATION'" |
  .env.HELM_REPO = "'$HELM_REPO'" |
  .env.APP_NAME = "'$APP_NAME'"
' $ACTION_FILE

echo 'GitHub Action Workflow files added'