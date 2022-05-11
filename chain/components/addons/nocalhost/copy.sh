#!/usr/bin/env bash

helm pull nocalhost --repo https://nocalhost.github.io/charts --version "${VERSION}"
mkdir -p "/scaffold/${OUTPUT_PATH}/infra"
tar -zxf "./nocalhost-${VERSION}.tgz" -C "/scaffold/${OUTPUT_PATH}/infra"
sed -i '/^metadata/a\  annotations:\n    helm.sh/hook: pre-install\n    helm.sh/hook-weight: "-10"' "/scaffold/${OUTPUT_PATH}/infra/nocalhost/templates/db-init-configmap.yaml"
cp /ingress/_helpers.tpl "/scaffold/${OUTPUT_PATH}/infra/nocalhost/templates/_helpers.tpl"
cp /ingress/ingress.yaml "/scaffold/${OUTPUT_PATH}/infra/nocalhost/templates/ingress.yaml"
# enable ingress
yq -i '.ingress.enabled = true | .ingress.hosts[0] = "'"$NOCALHOST_DOMAIN"'"' "/scaffold/${OUTPUT_PATH}/infra/nocalhost/values.yaml"
yq -i '.service.type = "ClusterIP"' "/scaffold/${OUTPUT_PATH}/infra/nocalhost/values.yaml"

# echo '{"username": "admin", "password": "123456", "url":"$NOCALHOST_DOMAIN"}' > "/scaffold/${OUTPUT_PATH}/infra/nocalhost-cd-output-hook.txt"

cat <<EOF > /scaffold/${OUTPUT_PATH}/infra/nocalhost-cd-output-hook.txt
{"username": "admin", "password": "123456", "url":"$NOCALHOST_DOMAIN"}
EOF
