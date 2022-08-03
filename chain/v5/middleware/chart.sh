#!/usr/bin/env bash

# set opts
# --repo
[ -n "${REPO}" ] && OPTS="${OPTS} --repo ${REPO}"
# --version
[ -n "${VERSION}" ] && OPTS="${OPTS} --version ${VERSION}"

helm_exec="helm pull ${CHART} ${OPTS}"
echo "$helm_exec"
$helm_exec

tar xf "${CHART}"-*.tgz
rm -rf "${CHART}"-*.tgz

if [ -n "$SET" ]; then
  cd "${CHART}" || exit 1
  set="yq -i '$SET' values.yaml"
  eval "$set"
fi
