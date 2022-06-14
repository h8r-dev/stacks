#!/usr/bin/env bash

export ADDON_FILE="/addon.yaml"

export PROMETHEUS_FILE="/prometheus.yaml"
export PROMETHEUS_DIR="/prometheus"

export GRAFANA_FILE="/grafana.yaml"
export GRAFANA_DIR="/grafana"

export LOKI_FILE="/loki.yaml"
export LOKI_DIR="/loki"

export ALERT_MANAGER_FILE="/alert-manager.yaml"
export ALERT_MANAGER_DIR="/alert-manager"

export ARGO_CD_FILE="/argo-cd.yaml"
export ARGO_CD_DIR="/argo-cd"

export SEALED_SECRETS_FILE="/sealed-secrets.yaml"
export SEALED_SECRETS_DIR="/sealed-secrets"

export DAPR_FILE="/dapr.yaml"
export DAPR_DIR="/dapr"

readComponent() {
    SRC_FILE=$1
    DST_DIR=$2
    mkdir -p ${DST_DIR}
    yq '.enabled' ${SRC_FILE} > "${DST_DIR}/enabled.txt"
    yq '.url' ${SRC_FILE} > "${DST_DIR}/url.txt"
    yq '.namespace' ${SRC_FILE} > "${DST_DIR}/namespace.txt"
    yq '.ingress' ${SRC_FILE} > "${DST_DIR}/ingress.txt"
    yq '.credentials' ${SRC_FILE} > "${DST_DIR}/credentials.txt"
    yq '.annotations' ${SRC_FILE} > "${DST_DIR}/annotations.txt"
}

readSealedSecrets() {
    SRC_FILE=$1
    DST_DIR=$2
    mkdir -p ${DST_DIR}
    yq '.enabled' ${SRC_FILE} > "${DST_DIR}/enabled.txt"
    yq '.tlscrt' ${SRC_FILE} > "${DST_DIR}/tlscrt.txt"
    yq '.tlskey' ${SRC_FILE} > "${DST_DIR}/tlskey.txt"
}

kubectl get cm/heighliner-infra-config -n heighliner-infra -o yaml | yq '.data.infra' > ${ADDON_FILE}

yq '.prometheus' ${ADDON_FILE} > ${PROMETHEUS_FILE}
readComponent ${PROMETHEUS_FILE} ${PROMETHEUS_DIR}

yq '.grafana' ${ADDON_FILE} > ${GRAFANA_FILE}
readComponent ${GRAFANA_FILE} ${GRAFANA_DIR}

yq '.loki' ${ADDON_FILE} > ${LOKI_FILE}
readComponent ${LOKI_FILE} ${LOKI_DIR}

yq '.alertManager' ${ADDON_FILE} > ${ALERT_MANAGER_FILE}
readComponent ${ALERT_MANAGER_FILE} ${ALERT_MANAGER_DIR}

yq '.argocd' ${ADDON_FILE} > ${ARGO_CD_FILE}
readComponent ${ARGO_CD_FILE} ${ARGO_CD_DIR}

yq '.sealedSecrets' ${ADDON_FILE} > ${SEALED_SECRETS_FILE}
readSealedSecrets ${SEALED_SECRETS_FILE} ${SEALED_SECRETS_DIR}

yq '.dapr' ${ADDON_FILE} > ${DAPR_FILE}
readComponent ${DAPR_FILE} ${DAPR_DIR}
