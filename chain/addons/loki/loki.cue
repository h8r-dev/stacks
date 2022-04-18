package loki

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
				helm pull loki-stack --repo https://grafana.github.io/helm-charts --version $VERSION
				mkdir -p /scaffold/$OUTPUT_PATH
				tar -zxvf ./loki-stack-$VERSION.tgz -C /scaffold/$OUTPUT_PATH
				mv /scaffold/$OUTPUT_PATH/loki-stack /scaffold/$OUTPUT_PATH/loki
			"""#
	}
	output: #Output & {
		image:   do.output
		success: do.success
	}
}
