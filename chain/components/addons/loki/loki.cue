package loki

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
			NETWORK_TYPE:       input.networkType
			CHART_URL_INTERNAL: origin.#Origin.loki.internal.url
			CHART_URL_GLOBAL:   origin.#Origin.loki.global.url
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
