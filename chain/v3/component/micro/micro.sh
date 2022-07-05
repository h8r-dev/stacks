#!/usr/bin/env bash

echo install ${NAME}
# helm create ${NAME}
# helm install --debug --dry-run backend ${NAME}

CLONE_URL=$(printf %s "${GIT_URL}" | sed 's/https:\/\/github.com/https:\/\/'${GITHUB_TOKEN}'@github.com/')

git clone ${CLONE_URL} /tmp/source
