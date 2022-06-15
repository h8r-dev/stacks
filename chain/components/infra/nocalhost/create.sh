#!/usr/bin/env bash

#helm pull nocalhost --repo https://nocalhost.github.io/charts --version "${VERSION}"
KEY="GLOBAL"
if [ "$NETWORK_TYPE" == "cn" ]; then
    KEY="INTERNAL"
fi
#NETWORK_TYPE="$(echo $NETWORK_TYPE | tr a-z A-Z)"
helm pull nocalhost --repo `eval echo '$'"CHART_URL_$KEY"` --version $VERSION

mkdir -p "/scaffold/${OUTPUT_PATH}/infra"
tar -zxf "./nocalhost-${VERSION}.tgz" -C "/scaffold/${OUTPUT_PATH}/infra"
sed -i '/^metadata/a\  annotations:\n    helm.sh/hook: pre-install\n    helm.sh/hook-weight: "-10"' "/scaffold/${OUTPUT_PATH}/infra/nocalhost/templates/db-init-configmap.yaml"
cp /ingress/_helpers.tpl "/scaffold/${OUTPUT_PATH}/infra/nocalhost/templates/_helpers.tpl"
cp /ingress/ingress.yaml "/scaffold/${OUTPUT_PATH}/infra/nocalhost/templates/ingress.yaml"

# Hardcode ingressClassName to be nginx
DEFAULT_INGRESS_CLASSNAME=nginx

# enable ingress
yq -i '.ingress.enabled = true | .ingress.hosts[0] = "'"$NOCALHOST_DOMAIN"'"' "/scaffold/${OUTPUT_PATH}/infra/nocalhost/values.yaml"
yq -i '.ingress.ingressClassName = "'$DEFAULT_INGRESS_CLASSNAME'"' "/scaffold/${OUTPUT_PATH}/infra/nocalhost/values.yaml"

yq -i '.service.type = "ClusterIP"' "/scaffold/${OUTPUT_PATH}/infra/nocalhost/values.yaml"

# echo '{"username": "admin", "password": "123456", "url":"$NOCALHOST_DOMAIN"}' > "/scaffold/${OUTPUT_PATH}/infra/nocalhost-cd-output-hook.txt"

cat <<EOF > /scaffold/${OUTPUT_PATH}/infra/nocalhost-cd-output-hook.txt
{"username": "admin@admin.com", "password": "123456", "url":"http://$NOCALHOST_DOMAIN", "infra": true}
EOF
