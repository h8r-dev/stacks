#!/usr/bin/env bash
KEY="GLOBAL"
if [ "$NETWORK_TYPE" == "cn" ]; then
    KEY="INTERNAL"
fi
CHART_NAME=dapr
helm pull $CHART_NAME --repo `eval echo '$'"CHART_URL_$KEY"` --version $VERSION
mkdir -p /scaffold/$OUTPUT_PATH/infra
tar -zxvf ./$CHART_NAME-$VERSION.tgz -C /scaffold/$OUTPUT_PATH/infra

# create dapr ingress for dapr dashboard
kubectl create ingress dapr-dashboard --rule="dapr.h8r.site/=dapr-dashboard:8080" --class=nginx --dry-run=client -o yaml > /scaffold/$OUTPUT_PATH/infra/$CHART_NAME/templates/ingress.yaml
yq -i '.metadata.annotations += {"nginx.ingress.kubernetes.io/auth-realm": "Authentication Required","nginx.ingress.kubernetes.io/auth-secret":"dapr/basic-auth","nginx.ingress.kubernetes.io/auth-type":"basic"}' /scaffold/$OUTPUT_PATH/infra/$CHART_NAME/templates/ingress.yaml
yq -i '.spec.rules[0].http.paths[0].pathType = "ImplementationSpecific"' /scaffold/$OUTPUT_PATH/infra/$CHART_NAME/templates/ingress.yaml


# basic auth for dapr dashboard
printf 'admin:$apr1$rviPk66W$HepYtRwZBa.Uvmi/pqK2N1' > auth
mkdir /scaffold/$OUTPUT_PATH/infra/$CHART_NAME/templates/basic-auth
kubectl create secret generic basic-auth --from-file auth --dry-run=client -o yaml > /scaffold/$OUTPUT_PATH/infra/$CHART_NAME/templates/basic-auth/basic-auth.yaml

cat <<EOF > /scaffold/${OUTPUT_PATH}/infra/dapr-cd-output-hook.txt
{"username": "admin", "password": "heighliner123!", "url":"http://$DAPR_DOMAIN", "infra": true}
EOF