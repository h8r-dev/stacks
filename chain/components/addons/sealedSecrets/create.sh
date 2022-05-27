#!/usr/bin/env bash
#helm pull sealed-secrets --repo https://bitnami-labs.github.io/sealed-secrets --version "${VERSION}"
KEY="GLOBAL"
if [[ "${NETWORK_TYPE}" == "china_network" ]]; then
    KEY="INTERNAL"
fi

echo "set sealed-secrets helm chart"
CHART_NAME=sealed-secrets
helm pull $CHART_NAME --repo "$(eval echo '$'"CHART_URL_$KEY")" --version "${VERSION}"
mkdir -p "/scaffold/${OUTPUT_PATH}/infra"
tar -zxf "./${CHART_NAME}-${VERSION}.tgz" -C "/scaffold/${OUTPUT_PATH}/infra"
