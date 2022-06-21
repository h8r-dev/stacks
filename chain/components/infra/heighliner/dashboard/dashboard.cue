package dashboard

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
			NAMESPACE:          input.namespace
			VERSION:            input.version
			OUTPUT_PATH:        input.helmName
			NETWORK_TYPE:       input.networkType
			CHART_URL_INTERNAL: origin.#Origin.dashboard.internal.url
			CHART_URL_GLOBAL:   origin.#Origin.dashboard.global.url
			WITHOUT_DASHBOARD:  input.withoutDashboard
			DOMAIN:             input.domain.infra.dashboard
		}
		mounts: kubeconfig: {
			dest:     "/root/.kube/config"
			contents: input.kubeconfig
		}
		mounts: Okubeconfig: {
			dest:     "/root/.kube/original-config"
			contents: input.originalKubeconfig
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
