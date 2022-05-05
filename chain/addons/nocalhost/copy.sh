#!/usr/bin/env bash

helm pull nocalhost --repo https://nocalhost.github.io/charts --version $VERSION
mkdir -p /scaffold/$OUTPUT_PATH/infra
tar -zxvf ./nocalhost-$VERSION.tgz -C /scaffold/$OUTPUT_PATH/infra
sed -i '/^metadata/a\  annotations:\n    helm.sh/hook: pre-install\n    helm.sh/hook-weight: "-10"' /scaffold/$OUTPUT_PATH/infra/nocalhost/templates/db-init-configmap.yaml
sed -i 's/LoadBalancer/ClusterIP/g' /scaffold/$OUTPUT_PATH/infra/nocalhost/values.yaml
#cat <<EOF > /scaffold/$OUTPUT_PATH/infra/nocalhost-cd-output-hook.sh
echo '{"username": "admin", "password": "123456"}' > /scaffold/$OUTPUT_PATH/infra/nocalhost-cd-output-hook.txt
#EOF
#chmod +x /scaffold/$OUTPUT_PATH/infra/nocalhost-cd-output-hook.sh