#! /usr/bin/env bash

TARGET_DIR=/scaffold/$REPO_NAME/.github/workflows

# Create github workflow dir
mkdir -p $TARGET_DIR

# Copy docker-publish.yaml file into target dir
mv $TEMPLATE_DIR/docker-publish.yaml $TARGET_DIR/

echo 'GitHub Action Workflow files added'