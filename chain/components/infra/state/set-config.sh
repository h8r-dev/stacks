#! /usr/bin/env bash

echo "Storing infra component state into ConfigMap"

export DEFAULT_USERNAME=admin
export DEFAULT_PASSWORD=heighliner123!

#------------------------------------
# Argocd
#------------------------------------
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d > /tmp/admin-password.txt

export ARGOCD_PASSWORD=$(cat /tmp/admin-password.txt)
export ARGOCD_URL="argocd-server.argocd.svc"

yq -i '
  .argocd.enabled = true |
  .argocd.url = env(ARGOCD_URL) |
  .argocd.namespace = "argocd" |
  .argocd.ingress = "http://argocd.h8r.site" |
  .argocd.credentials.username = "admin" |
  .argocd.credentials.password = env(ARGOCD_PASSWORD)
' config.yaml

#------------------------------------
# Prometheus
#------------------------------------
export PROMETHEUS_URL="prometheus-kube-prometheus-prometheus.${NAMESPACE}.svc:9090"
yq -i '
  .prometheus.enabled = true |
  .prometheus.namespace = env(NAMESPACE) |
  .prometheus.url = env(PROMETHEUS_URL) |
  .prometheus.ingress = "http://prometheus.h8r.site" |
  .prometheus.credentials.username = env(DEFAULT_USERNAME) |
  .prometheus.credentials.password = env(DEFAULT_PASSWORD)
' config.yaml

#------------------------------------
# Grafana
#------------------------------------
export GRAFANA_URL="prometheus-grafana.${NAMESPACE}.svc"
yq -i '
  .grafana.enabled = true |
  .grafana.namespace = env(NAMESPACE) |
  .grafana.url = env(GRAFANA_URL) |
  .grafana.ingress = "http://grafana.h8r.site" |
  .grafana.credentials.username = "admin" |
  .grafana.credentials.password = "prom-operator"
' config.yaml

#------------------------------------
# Alert Manager
#------------------------------------
export ALERTMANAGER_URL="prometheus-kube-prometheus-alertmanager.${NAMESPACE}.svc:9093"
yq -i '
  .alertManager.enabled = true |
  .alertManager.namespace = env(NAMESPACE) |
  .alertManager.url = env(ALERTMANAGER_URL) |
  .alertManager.ingress = "http://alert.h8r.site" |
  .alertManager.credentials.username = env(DEFAULT_USERNAME) |
  .alertManager.credentials.password = env(DEFAULT_PASSWORD)
' config.yaml

#------------------------------------
# Loki
#------------------------------------
yq -i '
  .loki.enabled = true |
  .loki.namespace = env(NAMESPACE)
' config.yaml

#------------------------------------
# Sealed secrets
#------------------------------------
export TLS_CERT="tls-cert"
export TLS_KEY="tls-private-key"
yq -i '
  .sealedSecrets.enabled = true |
  .sealedSecrets.namespace = env(NAMESPACE) |
  .sealedSecrets.tlscrt = env(TLS_CERT) |
  .sealedSecrets.tlskey = env(TLS_KEY)
' config.yaml

echo "Updated ConfigMap..."
cat config.yaml

# Create configmap
kubectl -n $NAMESPACE \
  create configmap heighliner-infra-config \
  --from-file=infra=config.yaml \
  -o yaml --dry-run=client | kubectl -n $NAMESPACE apply -f -