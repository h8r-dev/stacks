#!/usr/bin/env bash

ADDON_FILE=/addon.yaml
PROMETHEUS_FILE=/prometheus.yaml
GRAFANA_FILE=/grafana.yaml
LOKI_FILE=/loki.yaml
ALERT_MANAGER_FILE=/alert-manager.yaml
ARGO_CD_FILE=/argo-cd.yaml
SEALED_SECRETS_FILE=/sealed-secrets.yaml
DAPR_FILE=/dapr.yaml

kubectl get cm/heighliner-infra-config -n heighliner-infra -o yaml | yq '.data.infra' > ${ADDON_FILE}
yq '.prometheus' ${ADDON_FILE} > ${PROMETHEUS_FILE}
yq '.grafana' ${ADDON_FILE} > ${GRAFANA_FILE}
yq '.loki' ${ADDON_FILE} > ${LOKI_FILE}
yq '.alertManager' ${ADDON_FILE} > ${ALERT_MANAGER_FILE}
yq '.argocd' ${ADDON_FILE} > ${ARGO_CD_FILE}
yq '.sealedSecrets' ${ADDON_FILE} > ${SEALED_SECRETS_FILE}
yq '.dapr' ${ADDON_FILE} > ${DAPR_FILE}
