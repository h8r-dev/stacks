#!/usr/bin/env bash

KEY="GLOBAL"
if [[ "${NETWORK_TYPE}" == "cn" ]]; then
    KEY="INTERNAL"
fi

echo "Install sealed-secrets helm chart"
CHART_NAME=sealed-secrets

RELEASE_NAME="sealed"
# fix HELM UPGRADE FAILED: another operation (install/upgrade/rollback) is in progress
kubectl -n "$NAMESPACE" delete secret -l name="$RELEASE_NAME",status=pending-upgrade
kubectl -n "$NAMESPACE" delete secret -l name="$RELEASE_NAME",status=pending-install

helm upgrade $RELEASE_NAME $CHART_NAME \
    -n $NAMESPACE \
    --repo "$(eval echo '$'"CHART_URL_$KEY")" \
    --version "${VERSION}" \
    --install \
    --timeout 10m \
    --force \
    --cleanup-on-fail \
    --wait

echo "Install sealed-secrets helm chart Done."