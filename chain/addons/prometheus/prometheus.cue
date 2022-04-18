package prometheus

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
				helm pull kube-prometheus-stack --repo https://prometheus-community.github.io/helm-charts --version $VERSION
				mkdir -p /scaffold/$OUTPUT_PATH
				tar -zxvf ./kube-prometheus-stack-$VERSION.tgz -C /scaffold/$OUTPUT_PATH
				mv /scaffold/$OUTPUT_PATH/kube-prometheus-stack /scaffold/$OUTPUT_PATH/prometheus
			"""#
	}
	output: #Output & {
		image:   do.output
		success: do.success
	}
}
