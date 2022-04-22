package kind

import (
	"universe.dagger.io/bash"
)

#Instance: {
	input: #Input
	do:    bash.#Run & {
		"input": input.image
		env: {
			URL:         input.url
			OUTPUT_PATH: input.helmName
		}
		workdir: "/tmp"
		script: contents: #"""
				curl -O $URL
				mkdir -p /scaffold/$OUTPUT_PATH/infra/ingress-nginx
				mv deploy.yaml /scaffold/$OUTPUT_PATH/infra/ingress-nginx
			"""#
	}
	output: #Output & {
		image:   do.output
		success: do.success
	}
}
