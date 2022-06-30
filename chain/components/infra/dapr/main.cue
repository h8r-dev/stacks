package dapr

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
			NAMESPACE:          input.namespace
			VERSION:            input.version
			OUTPUT_PATH:        input.helmName
			NETWORK_TYPE:       input.networkType
			CHART_URL_INTERNAL: origin.#Origin.dapr.internal.url
			CHART_URL_GLOBAL:   origin.#Origin.dapr.global.url
			DAPR_DOMAIN:        input.domain.infra.dapr
		}
		mounts: kubeconfig: {
			dest:     "/root/.kube/config"
			type:     "secret"
			contents: input.kubeconfig
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
