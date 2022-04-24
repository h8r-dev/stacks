package nocalhost

import (
	"universe.dagger.io/bash"
)

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
				mkdir -p /scaffold/$OUTPUT_PATH/infra
				tar -zxvf ./nocalhost-$VERSION.tgz -C /scaffold/$OUTPUT_PATH/infra
				sed -i '/^metadata/a\  annotations:\n    helm.sh/hook: pre-install\n    helm.sh/hook-weight: "-10"' /scaffold/$OUTPUT_PATH/infra/nocalhost/templates/db-init-configmap.yaml
			"""#
	}
	output: #Output & {
		image:   do.output
		success: do.success
	}
}
