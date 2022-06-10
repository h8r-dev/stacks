#!/usr/bin/env bash

WORKFLOW_DIR=$SOURCE_CODE_DIR/.github/workflows

# Create github workflow dir
mkdir -p $WORKFLOW_DIR

# Copy docker-publish.yaml file into target dir
mv $WORKFLOW_SRC/docker-publish.yaml $WORKFLOW_DIR/

DOCKER_PUBLISH_FILE=$WORKFLOW_DIR/docker-publish.yaml

# Render docker-publish.yaml file with data provided
yq -i '
  .env.ORG = "'$ORGANIZATION'" |
  .env.HELM_REPO = "'$HELM_REPO'" |
  .env.APP_NAME = "'$APP_NAME'"
' $DOCKER_PUBLISH_FILE

echo 'GitHub Action Workflow files added'
