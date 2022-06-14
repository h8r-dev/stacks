#! /usr/bin/env bash

CHART_NAME=dapr
INFRA_DIR=/scaffold/$OUTPUT_PATH/infra
CHART_DIR=$INFRA_DIR/$CHART_NAME

#---------------------------------------------------------
# Pull Helm chart to $CHART_DIR and config it to match our needs
#---------------------------------------------------------
pull_heml_chart() {
  echo "Pulling dapr helm chart"

  KEY="GLOBAL"
  if [ "$NETWORK_TYPE" == "cn" ]; then
      KEY="INTERNAL"
  fi

  helm pull $CHART_NAME --repo `eval echo '$'"CHART_URL_$KEY"` --version $VERSION

  mkdir -p $INFRA_DIR
  tar -zxf ./$CHART_NAME-$VERSION.tgz -C $INFRA_DIR
}

#---------------------------------------------------------
# Create dapr ingress for dapr dashboard
#---------------------------------------------------------
create_ingress_settings() {
  echo "Creating dapr ingress"

  kubectl create ingress dapr-dashboard \
    --rule="dapr.h8r.site/=dapr-dashboard:8080" \
    --class=nginx \
    --dry-run=client \
    -o yaml > $CHART_DIR/templates/ingress.yaml

  yq -i '
    .metadata.annotations += {
      "nginx.ingress.kubernetes.io/auth-realm": "Authentication Required",
      "nginx.ingress.kubernetes.io/auth-secret":"dapr/basic-auth",
      "nginx.ingress.kubernetes.io/auth-type":"basic"
    } |
    .spec.rules[0].http.paths[0].pathType = "ImplementationSpecific"
  ' $CHART_DIR/templates/ingress.yaml
}

#---------------------------------------------------------
# Create auth identity for dapr dashboard
# username: admin
# password: heighliner123!
#---------------------------------------------------------
create_auth_identity() {
  printf 'admin:$apr1$rviPk66W$HepYtRwZBa.Uvmi/pqK2N1' > auth.txt
  mkdir -p $CHART_DIR/templates/basic-auth

  secret_name=$CHART_NAME-basic-auth
  kubectl create secret generic $secret_name \
    --from-file auth.txt \
    --dry-run=client \
    -o yaml > $CHART_DIR/templates/basic-auth/basic-auth.yaml
}

install() {
  helm install $CHART_DIR --generate-name
}

pull_heml_chart

create_ingress_settings

create_auth_identity

install

# cat <<EOF > /scaffold/${OUTPUT_PATH}/infra/dapr-cd-output-hook.txt
# {"username": "admin", "password": "heighliner123!", "url":"http://$DAPR_DOMAIN", "infra": true}
# EOF