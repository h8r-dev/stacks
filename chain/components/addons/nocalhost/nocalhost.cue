package nocalhost

import (
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/components/origin"
)

#Instance: {
	input: #Input
	src:   core.#Source & {
		path: "."
	}
	do: bash.#Run & {
		"input": input.image
		env: {
			VERSION:            input.version
			OUTPUT_PATH:        input.helmName
			NOCALHOST_DOMAIN:   input.domain.infra.nocalhost
			NETWORK_TYPE:       input.networkType
			CHART_URL_INTERNAL: origin.#Origin.nocalhost.internal.url
			CHART_URL_GLOBAL:   origin.#Origin.nocalhost.global.url
		}
		workdir: "/tmp"
		script: {
			directory: src.output
			filename:  "create.sh"
		}
		mounts: ingress: {
			dest:     "/ingress"
			contents: src.output
		}
	}
	output: #Output & {
		image:   do.output
		success: do.success
	}
}
