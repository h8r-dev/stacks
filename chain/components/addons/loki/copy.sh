#!/usr/bin/env bash
NETWORK_TYPE="$(echo $NETWORK_TYPE | tr a-z A-Z)"
helm pull loki-stack --repo `eval echo '$'"CHART_URL_$NETWORK_TYPE"` --version $VERSION
#if [ "$NETWORK_TYPE" == "internal" ]; then
#    helm pull loki-stack --repo $CHART_URL_INTERNAL --version $VERSION
#else
#    helm pull loki-stack --repo $CHART_URL_GLOBAL --version $VERSION
#fi
#helm pull loki-stack --repo https://grafana.github.io/helm-charts --version $VERSION
mkdir -p /scaffold/$OUTPUT_PATH/infra
tar -zxvf ./loki-stack-$VERSION.tgz -C /scaffold/$OUTPUT_PATH/infra
mv /scaffold/$OUTPUT_PATH/infra/loki-stack /scaffold/$OUTPUT_PATH/infra/loki