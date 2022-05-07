package cloud

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
			REPOSITORY:  input.repository
		}
		workdir: "/tmp"
		script: contents: #"""
				chartName="ingress-nginx"
				helm pull $chartName --repo $REPOSITORY --version $VERSION
				mkdir -p /scaffold/$OUTPUT_PATH/infra
				tar -zxvf ./$chartName-$VERSION.tgz -C /scaffold/$OUTPUT_PATH/infra
				mv /scaffold/$OUTPUT_PATH/infra/$chartName /scaffold/$OUTPUT_PATH/infra/$chartName
			"""#
	}
	output: #Output & {
		image:   do.output
		success: do.success
	}
}
