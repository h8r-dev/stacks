#!/usr/bin/env bash

# Fetch kube-prometheus-stack helm chart
#helm pull kube-prometheus-stack --repo https://prometheus-community.github.io/helm-charts --version $VERSION
NETWORK_TYPE="$(echo $NETWORK_TYPE | tr a-z A-Z)"
helm pull kube-prometheus-stack --repo `eval echo '$'"CHART_URL_$NETWORK_TYPE"` --version $VERSION

mkdir -p /scaffold/$OUTPUT_PATH/infra
tar -zxvf ./kube-prometheus-stack-$VERSION.tgz -C /scaffold/$OUTPUT_PATH/infra
mv /scaffold/$OUTPUT_PATH/infra/kube-prometheus-stack /scaffold/$OUTPUT_PATH/infra/prometheus-stack

# write basic auth username and password to file
# default password is heighliner123!
# gernerate by htpasswd -c auth admin
printf 'admin:$apr1$rviPk66W$HepYtRwZBa.Uvmi/pqK2N1' > auth

# Hardcode ingressClassName to be nginx
DEFAULT_INGRESS_CLASSNAME=nginx

# set customResource replace mode for argocd: https://github.com/argoproj/argo-cd/issues/8128
# add annotation for ./prometheus/crds/crd-prometheuses.yaml: argocd.argoproj.io/sync-options: Replace=true
yq -i '.metadata.annotations += {"argocd.argoproj.io/sync-options": "Replace=true"}' /scaffold/$OUTPUT_PATH/infra/prometheus-stack/crds/crd-prometheuses.yaml

# enable grafana ingress
yq -i '.grafana.ingress.enabled = true | .grafana.ingress.hosts[0] = "'$GRAFANA_DOMAIN'"' /scaffold/$OUTPUT_PATH/infra/prometheus-stack/values.yaml
yq -i '.grafana.ingress.ingressClassName = "'$DEFAULT_INGRESS_CLASSNAME'"' /scaffold/$OUTPUT_PATH/infra/prometheus-stack/values.yaml

# enable alertManager ingress
yq -i '.alertmanager.ingress.enabled = true | .alertmanager.ingress.hosts[0] = "'$ALERTMANAGER_DOMAIN'"' /scaffold/$OUTPUT_PATH/infra/prometheus-stack/values.yaml
yq -i '.alertmanager.ingress.ingressClassName = "'$DEFAULT_INGRESS_CLASSNAME'"' /scaffold/$OUTPUT_PATH/infra/prometheus-stack/values.yaml
yq -i '.alertmanager.ingress.annotations += {"nginx.ingress.kubernetes.io/auth-realm": "Authentication Required","nginx.ingress.kubernetes.io/auth-secret":"prometheus-stack/basic-auth","nginx.ingress.kubernetes.io/auth-type":"basic"}' /scaffold/$OUTPUT_PATH/infra/prometheus-stack/values.yaml
# create basic-auth secret file for alertManager and prometheus basic auth
mkdir /scaffold/$OUTPUT_PATH/infra/prometheus-stack/templates/basic-auth
kubectl create secret generic basic-auth --from-file auth --dry-run=client -o yaml > /scaffold/$OUTPUT_PATH/infra/prometheus-stack/templates/basic-auth/basic-auth.yaml

# enable prometheus ingress
yq -i '.prometheus.ingress.enabled = true | .prometheus.ingress.hosts[0] = "'$PROMETHEUS_DOMAIN'"' /scaffold/$OUTPUT_PATH/infra/prometheus-stack/values.yaml
yq -i '.prometheus.ingress.ingressClassName = "'$DEFAULT_INGRESS_CLASSNAME'"' /scaffold/$OUTPUT_PATH/infra/prometheus-stack/values.yaml
yq -i '.prometheus.ingress.annotations += {"nginx.ingress.kubernetes.io/auth-realm": "Authentication Required","nginx.ingress.kubernetes.io/auth-secret":"prometheus-stack/basic-auth","nginx.ingress.kubernetes.io/auth-type":"basic"}' /scaffold/$OUTPUT_PATH/infra/prometheus-stack/values.yaml

# add grafana loki datasource
yq -i '.grafana.additionalDataSources[0] = {"name": "loki", "type": "loki", "url": "http://loki.loki:3100/", "access": "proxy"}' /scaffold/$OUTPUT_PATH/infra/prometheus-stack/values.yaml

# prometheus sd config
yq -i '.prometheus.prometheusSpec.additionalScrapeConfigs += {"job_name": "'service'"}' /scaffold/$OUTPUT_PATH/infra/prometheus-stack/values.yaml
yq -i '.prometheus.prometheusSpec.additionalScrapeConfigs[-1].kubernetes_sd_configs[0].role = "service"' /scaffold/$OUTPUT_PATH/infra/prometheus-stack/values.yaml

# Add application dashboards
if [ -d "/dashboards" ]; then
    cp /dashboards/*.yaml /scaffold/$OUTPUT_PATH/infra/prometheus-stack/templates/grafana/dashboards-1.14/
fi

# Add dashboardRefs output hook
if [ -f /dashboards/*annotations.json ]; then
    for file in /dashboards/*annotations.json
    do
        # TODO: Combine files
        TMP_CONTENTS=$(base64 $file | tr -d '\n')
    done
fi

# add spring boot serviceMonitor
yq -i '.prometheus.additionalServiceMonitors += {"name": "spring-service-monitor", "namespaceSelector": {"any": true}, "selector": {"matchLabels": {"h8r.io/framework": "spring"}}, "endpoints": [{"path": "/actuator/prometheus", "targetPort": "http"}]}' /scaffold/$OUTPUT_PATH/infra/prometheus-stack/values.yaml
#cat <<EOF > /scaffold/$OUTPUT_PATH/infra/prometheus-cd-output-hook.sh
#echo {"username": "admin", "password": "prom-operator","OUTPUT_PATH":"$OUTPUT_PATH","TEST_ENV":"$TEST_ENV"} > /scaffold/$OUTPUT_PATH/infra/prometheus-cd-output-hook.txt

cat <<EOF >  /scaffold/$OUTPUT_PATH/infra/prometheus-stack-cd-output-hook.txt
{"url": "http://$GRAFANA_DOMAIN", "username": "admin", "password": "prom-operator","infra": true, "type": "monitoring", "annotations": "$TMP_CONTENTS", \
"prompt":"prometheus URL: http://$PROMETHEUS_DOMAIN [Username: admin Password: heighliner123!], alertManager URL: http://$ALERTMANAGER_DOMAIN [Username: admin Password: heighliner123!]"}
EOF

#chmod +x /scaffold/$OUTPUT_PATH/infra/prometheus-cd-output-hook.sh