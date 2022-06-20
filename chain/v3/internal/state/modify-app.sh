#!/usr/bin/env bash

APPLICATION_FILE=/application.yaml

yq -i '
    .metadata = {
        "name": "'${APP_NAME}'",
        "namespace": "'${NAMESPACE}'",
        "labels": {
            "app.heighliner.dev/name": "'${APP_NAME}'"
        }
    } |
    .spec = {
        "name": "'${APP_NAME}'",
        "stack": {
            "name": "'${STACK_NAME}'",
            "version": "'${STACK_VERSION}'"
        }
    }
    ' ${APPLICATION_FILE}

# cat ${APPLICATION_FILE}
