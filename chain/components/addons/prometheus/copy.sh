#!/usr/bin/env bash

helm pull kube-prometheus-stack --repo https://prometheus-community.github.io/helm-charts --version $VERSION
mkdir -p /scaffold/$OUTPUT_PATH/infra
tar -zxvf ./kube-prometheus-stack-$VERSION.tgz -C /scaffold/$OUTPUT_PATH/infra
mv /scaffold/$OUTPUT_PATH/infra/kube-prometheus-stack /scaffold/$OUTPUT_PATH/infra/prometheus

# set customResource replace mode for argocd: https://github.com/argoproj/argo-cd/issues/8128
# add annotation for ./prometheus/crds/crd-prometheuses.yaml: argocd.argoproj.io/sync-options: Replace=true
yq -i '.metadata.annotations += {"argocd.argoproj.io/sync-options": "Replace=true"}' /scaffold/$OUTPUT_PATH/infra/prometheus/crds/crd-prometheuses.yaml
# enable grafana ingress
yq -i '.grafana.ingress.enabled = true | .grafana.ingress.hosts[0] = "'$GRAFANA_DOMAIN'"' /scaffold/$OUTPUT_PATH/infra/prometheus/values.yaml
# enable alertManager ingress
yq -i '.alertmanager.ingress.enabled = true | .alertmanager.ingress.hosts[0] = "'$ALERTMANAGER_DOMAIN'"' /scaffold/$OUTPUT_PATH/infra/prometheus/values.yaml
# enable prometheus ingress
yq -i '.prometheus.ingress.enabled = true | .prometheus.ingress.hosts[0] = "'$PROMETHEUS_DOMAIN'"' /scaffold/$OUTPUT_PATH/infra/prometheus/values.yaml
# add grafana loki datasource
yq -i '.grafana.additionalDataSources[0] = {"name": "loki", "type": "loki", "url": "http://loki.loki:3100/", "access": "proxy"}' /scaffold/$OUTPUT_PATH/infra/prometheus/values.yaml
# prometheus sd config
yq -i '.prometheus.prometheusSpec.additionalScrapeConfigs += {"job_name": "'service'"}' /scaffold/$OUTPUT_PATH/infra/prometheus/values.yaml
yq -i '.prometheus.prometheusSpec.additionalScrapeConfigs[-1].kubernetes_sd_configs[0].role = "service"' /scaffold/$OUTPUT_PATH/infra/prometheus/values.yaml
# Add application dashboards
if [ -d "/dashboards" ]; then
    cp /dashboards/*.yaml /scaffold/$OUTPUT_PATH/infra/prometheus/templates/grafana/dashboards-1.14/
fi
# Add dashboardRefs output hook
if [ -f /dashboards/*annotations.json ]; then
    for file in /dashboards/*annotations.json
    do
        # TODO: Combine files
        TMP_CONTENTS=$(base64 $file | tr -d '\n')
    done
fi
#cat <<EOF > /scaffold/$OUTPUT_PATH/infra/prometheus-cd-output-hook.sh
#echo {"username": "admin", "password": "prom-operator","OUTPUT_PATH":"$OUTPUT_PATH","TEST_ENV":"$TEST_ENV"} > /scaffold/$OUTPUT_PATH/infra/prometheus-cd-output-hook.txt
cat <<EOF >  /scaffold/$OUTPUT_PATH/infra/prometheus-cd-output-hook.txt
{"url": "$GRAFANA_DOMAIN", "username": "admin", "password": "prom-operator", "type": "monitoring", "annotations": "$TMP_CONTENTS", \
"prompt":"Prometheus's url is $PROMETHEUS_DOMAIN ; AlertManager's url is $ALERTMANAGER_DOMAIN"}
EOF
#chmod +x /scaffold/$OUTPUT_PATH/infra/prometheus-cd-output-hook.sh

