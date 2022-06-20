#!/usr/bin/env bash

ENVIRONMENT_FILE=/environment.yaml

yq -i '
    .metadata = {
        "name": "'${APP_NAME}-${DEVSPACE_NAME}'",
        "namespace": "'${NAMESPACE}'",
        "labels": {
            "app.heighliner.dev/name": "'${APP_NAME}'"
        }
    } |
    .spec = {
        "name": "'${DEVSPACE_NAME}'",
        "namespace": "'${DEVSPACE_NAMEPSACE}'",
        "access": {
            "previewURL": "'${PREVIEW_URL}'"
        },
        "chart": {
            "version": "'${CHART_VERSION}'",
            "url": "'${CHART_URL}'",
            "type": "'${CHART_TYPE}'",
            "path": "'${CHART_PATH}'",
            "valuesFile": "'${CHART_VALUES_FILE}'",
            "defaultBranch": "'${CHART_DEFAULT_BRANCH}'"
        }
    }
    ' ${ENVIRONMENT_FILE}

# cat ${ENVIRONMENT_FILE}
