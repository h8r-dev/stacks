#!/usr/bin/env bash

REPO_FILE=/repository.yaml

yq -i '
    .metadata = {
        "name": "'${APP_NAME}-${REPO_NAME}'",
        "namespace": "'${NAMESPACE}'",
        "labels": {
            "app.heighliner.dev/name": "'${APP_NAME}'"
        }
    } |
    .spec = { 
        "appName": "'${APP_NAME}'",
        "source": { 
            "name": "'${REPO_NAME}'",
            "type": "'${REPO_TYPE}'",
            "url": "'${REPO_URL}'",
            "provider": "'${PROVIDER}'",
            "organization": "'${ORGANIZATION}'"
        }
    }
    ' ${REPO_FILE}

# cat ${REPO_FILE}
