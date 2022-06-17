#!/usr/bin/env bash

KEY="GLOBAL"
if [ "$NETWORK_TYPE" == "cn" ]; then
    KEY="INTERNAL"
fi

RELEASE_NAME="hln"
# fix HELM UPGRADE FAILED: another operation (install/upgrade/rollback) is in progress
kubectl -n "$NAMESPACE" delete secret -l name="$RELEASE_NAME",status=pending-upgrade
kubectl -n "$NAMESPACE" delete secret -l name="$RELEASE_NAME",status=pending-install

ORIGINAL_KUBECONFIG=$(< /root/.kube/original-config base64)
echo "ORIGINAL_KUBECONFIG: ${ORIGINAL_KUBECONFIG}"

helm upgrade $RELEASE_NAME heighliner-cloud \
    -n $NAMESPACE \
    --repo `eval echo '$'"CHART_URL_$KEY"`\
    --version $VERSION \
    --install \
    --timeout 10m \
    --set "heighliner-cloud-backend.initCluster.kubeconfig=${ORIGINAL_KUBECONFIG}" \
    --wait

echo "Install heighliner-dashboard helm chart Done."