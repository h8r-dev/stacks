#!/usr/bin/env bash

TIMEOUT=${TIMEOUT:-"10m"}
WAIT=${WAIT:-"false"}
ATOMIC=${ATOMIC:-"false"}

# set opts
# --timeout
OPTS="${OPTS} --timeout ${TIMEOUT}"
# --namespace
OPTS="${OPTS} --namespace ${NAMESPACE}"
# --repo
[ -n "${REPO}" ] && OPTS="${OPTS} --repo ${REPO}"
# --set
[ -n "${SET}" ] && OPTS="${OPTS} --set ${SET}"
# --values
if [ -n "${VALUES}" ]; then
  printf %s "${VALUES}" > /tmp/helm_values.yaml
  OPTS="${OPTS} --values /tmp/helm_values.yaml"
fi
# --version
[ -n "${VERSION}" ] && OPTS="${OPTS} --version ${VERSION}"
# --wait
[ "$WAIT" == "true" ] && OPTS="${OPTS} --wait"
# --atomic
[ "$ATOMIC" == "true" ] && OPTS="${OPTS} --atomic"

# set chart
[ -n "${CHART_PATH}" ] && CHART=".${CHART_PATH}"

# create namespace
set +e
kubectl create namespace "${NAMESPACE}" > /dev/null 2>&1
set -e

# Try delete pending-upgrade helm release
# https://github.com/helm/helm/issues/4558
kubectl -n "${NAMESPACE}" delete secret -l name="${NAME}",status=pending-upgrade
kubectl -n "${NAMESPACE}" delete secret -l name="${NAME}",status=pending-install

helm_exec="helm upgrade ${NAME} ${CHART} ${OPTS} --install --dependency-update"
echo "${helm_exec}"
$helm_exec

