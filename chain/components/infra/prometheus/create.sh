#! /usr/bin/env bash

CHART_NAME=prometheus-stack
CHART_DIR=/scaffold/$OUTPUT_PATH/infra/$CHART_NAME

#---------------------------------------------------------
# Pull Helm chart to $CHART_DIR and config it to match our needs
#---------------------------------------------------------
pull_heml_chart() {
  echo "Pulling prometheus-stack helm chart"

  KEY="GLOBAL"
  if [ "$NETWORK_TYPE" == "cn" ]; then
      KEY="INTERNAL"
  fi

  helm pull kube-prometheus-stack \
    --repo `eval echo '$'"CHART_URL_$KEY"` \
    --version $VERSION

  mkdir -p /scaffold/$OUTPUT_PATH/infra
  tar -zxf ./kube-prometheus-stack-$VERSION.tgz -C /scaffold/$OUTPUT_PATH/infra
  mv /scaffold/$OUTPUT_PATH/infra/kube-prometheus-stack $CHART_DIR

  echo "Pulling prometheus-stack helm chart Done."
}

#---------------------------------------------------------
# Config ingress settings for multi components
#---------------------------------------------------------
config_ingress_settings() {
  INGRESS_CLASSNAME=nginx

  # enable grafana ingress
  yq -i '
    .grafana.ingress.enabled = true |
    .grafana.ingress.hosts[0] = "'$GRAFANA_DOMAIN'" |
    .grafana.ingress.ingressClassName = "'$INGRESS_CLASSNAME'"
  ' $CHART_DIR/values.yaml

  # enable alertManager ingress
  yq -i '
    .alertmanager.ingress.enabled = true |
    .alertmanager.ingress.hosts[0] = "'$ALERTMANAGER_DOMAIN'" |
    .alertmanager.ingress.ingressClassName = "'$INGRESS_CLASSNAME'" |
    .alertmanager.ingress.annotations += {
        "nginx.ingress.kubernetes.io/auth-realm": "Authentication Required",
        "nginx.ingress.kubernetes.io/auth-secret": "'$NAMESPACE'/'$CHART_NAME'-basic-auth",
        "nginx.ingress.kubernetes.io/auth-type": "basic"
    }
  ' $CHART_DIR/values.yaml

  # enable prometheus ingress
  yq -i '
    .prometheus.ingress.enabled = true |
    .prometheus.ingress.ingressClassName = "'$INGRESS_CLASSNAME'" |
    .prometheus.ingress.hosts[0] = "'$PROMETHEUS_DOMAIN'" |
    .prometheus.ingress.annotations += {
        "nginx.ingress.kubernetes.io/auth-realm": "Authentication Required",
        "nginx.ingress.kubernetes.io/auth-secret": "'$NAMESPACE'/'$CHART_NAME'-basic-auth",
        "nginx.ingress.kubernetes.io/auth-type": "basic"
    }
  ' $CHART_DIR/values.yaml
}

#---------------------------------------------------------
# Config default password for services.
# username: admin
# password: heighliner123!
#---------------------------------------------------------
config_default_password() {
  printf 'admin:$apr1$rviPk66W$HepYtRwZBa.Uvmi/pqK2N1' > auth
  dir=$CHART_DIR/templates/basic-auth
  mkdir -p $dir

  secret_name=$CHART_NAME-basic-auth
  kubectl create secret generic $secret_name \
    --from-file auth \
    --dry-run=client \
    -o yaml > $dir/basic-auth.yaml
}

#---------------------------------------------------------
# Config Misc settings.
#---------------------------------------------------------
config_misc() {
  # add grafana loki datasource
  yq -i '
    .grafana.additionalDataSources[0] = {
        "name": "loki",
        "type": "loki",
        "access": "proxy",
        "url": "http://loki.loki:3100/"
    }
  ' $CHART_DIR/values.yaml

  # Config hln alert rules
  # convention: rules created by hln stack will have the label: "role: hln-rules"
  yq -i '
    .prometheus.prometheusSpec.ruleSelector = {
      "matchLabels": {"role": "hln-rules"}
    }
  ' $CHART_DIR/values.yaml
}

#---------------------------------------------------------
# Install helm chart
#---------------------------------------------------------
install() {
  RELEASE_NAME="prometheus"
  # fix HELM UPGRADE FAILED: another operation (install/upgrade/rollback) is in progress
  kubectl -n "$NAMESPACE" delete secret -l name="$RELEASE_NAME",status=pending-upgrade
  kubectl -n "$NAMESPACE" delete secret -l name="$RELEASE_NAME",status=pending-install

  echo "Installing $CHART_NAME and waiting for it to be ready..."
  helm upgrade $RELEASE_NAME $CHART_DIR \
    -n $NAMESPACE \
    --install \
    --timeout 10m \
    --wait
}

pull_heml_chart

config_ingress_settings

config_default_password

config_misc

install