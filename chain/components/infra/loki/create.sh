#!/usr/bin/env bash

KEY="GLOBAL"
if [ "$NETWORK_TYPE" == "cn" ]; then
    KEY="INTERNAL"
fi

RELEASE_NAME="loki"
# fix HELM UPGRADE FAILED: another operation (install/upgrade/rollback) is in progress
kubectl -n "$NAMESPACE" delete secret -l name="$RELEASE_NAME",status=pending-upgrade
kubectl -n "$NAMESPACE" delete secret -l name="$RELEASE_NAME",status=pending-install

helm upgrade $RELEASE_NAME loki-stack \
    -n $NAMESPACE \
    --repo `eval echo '$'"CHART_URL_$KEY"`\
    --version $VERSION \
    --install \
    --force \
    --set loki.isDefault=false \
    --cleanup-on-fail \
    --timeout 10m \
    --wait

echo "Install loki-stack helm chart Done."