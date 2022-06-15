#!/usr/bin/env bash

# argocd
echo "set argocd config"
# argocd_password=$(kubectl -n "${NAMESPACE}" get secret -n heighliner-infra argocd-initial-admin-secret -o=jsonpath='{.data.password}'|base64 -d)
# argocd_url="argo-argocd-server.${NAMESPACE}.svc"
argocd_password=$(kubectl -n argocd get secret -n heighliner-infra argocd-initial-admin-secret -o=jsonpath='{.data.password}'|base64 -d)
argocd_url="argocd-server.argocd.svc"

yq -i '.argocd.url = "'"$argocd_url"'"' config.yaml
yq -i '.argocd.credentials.username = "admin"' config.yaml
yq -i '.argocd.credentials.password = "'"$argocd_password"'"' config.yaml

kubectl -n "${NAMESPACE}" create configmap heighliner-infra-config --from-file=infra=config.yaml