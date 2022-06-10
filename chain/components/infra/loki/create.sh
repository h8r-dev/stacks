#!/usr/bin/env bash

KEY="GLOBAL"
if [ "$NETWORK_TYPE" == "china_network" ]; then
    KEY="INTERNAL"
fi

helm install loki-stack \
    --repo `eval echo '$'"CHART_URL_$KEY"`\
    --version $VERSION \
    --generate-name

echo "Install loki-stack helm chart Done."