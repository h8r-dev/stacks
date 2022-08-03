#!/usr/bin/env bash

TEMP_FILE_NAME="docker-publish.yaml"
# Render docker-publish.yaml file with data provided
yq -i '
  .env.ORG = "'$ORGANIZATION'" |
  .env.HELM_REPO = "'$HELM_REPO'" |
  .env.APP_NAME = "'$APP_NAME'"
' $TEMP_FILE_NAME

mv ${TEMP_FILE_NAME} ${WANTED_FILE_NAME}
