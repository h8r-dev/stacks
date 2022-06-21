package dapr

import (
	"dagger.io/dagger/core"
	"github.com/h8r-dev/stacks/chain/components/origin"
	"universe.dagger.io/bash"
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
			NETWORK_TYPE:       input.networkType
			CHART_URL_INTERNAL: origin.#Origin.dapr.internal.url
			CHART_URL_GLOBAL:   origin.#Origin.dapr.global.url
			DAPR_DOMAIN:        input.domain.infra.dapr
		}
		workdir: "/tmp"
		script: {
			directory: src.output
			filename:  "create.sh"
		}
	}
	output: #Output & {
		image:   do.output
		success: do.success
	}
}
