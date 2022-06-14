#!/usr/bin/env bash

KEY="GLOBAL"
if [ "$NETWORK_TYPE" == "cn" ]; then
    KEY="INTERNAL"
fi

helm install loki-stack \
    -n $NAMESPACE \
    --repo `eval echo '$'"CHART_URL_$KEY"`\
    --version $VERSION \
    --generate-name \
    --wait

echo "Install loki-stack helm chart Done."