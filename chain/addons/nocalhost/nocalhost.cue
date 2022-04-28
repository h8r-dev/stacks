package nocalhost

import (
	"universe.dagger.io/bash"
)

// TODO generate nocalhost ingress yaml
#Instance: {
	input: #Input
	do:    bash.#Run & {
		"input": input.image
		env: {
			VERSION:     input.version
			OUTPUT_PATH: input.helmName
		}
		workdir: "/tmp"
		script: contents: #"""
				helm pull nocalhost --repo https://nocalhost.github.io/charts --version $VERSION
				mkdir -p /scaffold/$OUTPUT_PATH/infra/nocalhost
				tar -zxvf ./nocalhost-$VERSION.tgz -C /scaffold/$OUTPUT_PATH/infra/nocalhost
				mv /scaffold/$OUTPUT_PATH/infra/nocalhost/nocalhost /scaffold/$OUTPUT_PATH/infra/nocalhost/app
				sed -i '/^metadata/a\  annotations:\n    helm.sh/hook: pre-install\n    helm.sh/hook-weight: "-10"' /scaffold/$OUTPUT_PATH/infra/nocalhost/app/templates/db-init-configmap.yaml
				sed -i 's/LoadBalancer/ClusterIP/g' /scaffold/$OUTPUT_PATH/infra/nocalhost/app/values.yaml
				echo "nocalhost..."
				cat <<EOF > /scaffold/$OUTPUT_PATH/infra/nocalhost/output-hook.sh
				echo '{"username": "admin", "password": "123456"}'
				EOF
				chmod +x /scaffold/$OUTPUT_PATH/infra/nocalhost/output-hook.sh
			"""#
	}
	output: #Output & {
		image:   do.output
		success: do.success
	}
}
