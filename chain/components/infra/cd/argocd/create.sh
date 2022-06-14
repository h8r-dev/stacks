#!/usr/bin/env bash

KEY="GLOBAL"
if [ "$NETWORK_TYPE" == "cn" ]; then
    KEY="INTERNAL"
fi

RELEASE_NAME="argo"
# fix HELM UPGRADE FAILED: another operation (install/upgrade/rollback) is in progress
kubectl -n "$NAMESPACE" delete secret -l name="$RELEASE_NAME",status=pending-upgrade
kubectl -n "$NAMESPACE" delete secret -l name="$RELEASE_NAME",status=pending-install

helm upgrade $RELEASE_NAME argo-cd \
    -n $NAMESPACE \
    --repo `eval echo '$'"CHART_URL_$KEY"`\
    --version $VERSION \
    --install \
    --timeout 10m \
    --wait

echo "Install argocd helm chart Done."