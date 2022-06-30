package prometheus

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
			NAMESPACE:           input.namespace
			VERSION:             input.version
			HELM_NAME:           input.helmName
			OUTPUT_PATH:         input.helmName
			GRAFANA_DOMAIN:      input.domain.infra.grafana
			ALERTMANAGER_DOMAIN: input.domain.infra.alertManager
			PROMETHEUS_DOMAIN:   input.domain.infra.prometheus
			NETWORK_TYPE:        input.networkType
			CHART_URL_INTERNAL:  origin.#Origin.prometheus.internal.url
			CHART_URL_GLOBAL:    origin.#Origin.prometheus.global.url
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
