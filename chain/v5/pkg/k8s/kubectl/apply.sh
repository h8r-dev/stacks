#!/usr/bin/env bash

[ -n "${NAMESPACE}" ] && OPTS="${OPTS} --namespace ${NAMESPACE}"
# --wait
[ "${WAIT}" == "true" ] && OPTS="${OPTS} --wait"

# --namespace
if [ -n "${NAMESPACE}" ]; then
  # create namespace
  set +e
  kubectl create namespace "${NAMESPACE}" > /dev/null 2>&1
  set -e
  OPTS="${OPTS} --namespace ${NAMESPACE}"
fi

filename="./"
[ "${TYPE}" == "url" ] && filename=$(cat ./manifest.yaml)

kubectl_exec="kubectl apply ${OPTS} -f ${filename}"
$kubectl_exec
