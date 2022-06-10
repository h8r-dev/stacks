#!/usr/bin/env bash

KEY="GLOBAL"
if [[ "${NETWORK_TYPE}" == "china_network" ]]; then
    KEY="INTERNAL"
fi

echo "Install sealed-secrets helm chart"
CHART_NAME=sealed-secrets
helm install $CHART_NAME \
    --repo "$(eval echo '$'"CHART_URL_$KEY")" \
    --version "${VERSION}" \
    --generate-name

echo "Install sealed-secrets helm chart Done."