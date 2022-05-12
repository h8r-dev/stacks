#!/usr/bin/env bash

helm pull loki-stack --repo https://grafana.github.io/helm-charts --version $VERSION
mkdir -p /scaffold/$OUTPUT_PATH/infra
tar -zxvf ./loki-stack-$VERSION.tgz -C /scaffold/$OUTPUT_PATH/infra
mv /scaffold/$OUTPUT_PATH/infra/loki-stack /scaffold/$OUTPUT_PATH/infra/loki

cat <<EOF > /scaffold/${OUTPUT_PATH}/infra/loki-cd-output-hook.txt
{"infra": "true"}
EOF