package prometheus

import (
	"universe.dagger.io/bash"
	"dagger.io/dagger/core"
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
			VERSION:             input.version
			OUTPUT_PATH:         input.helmName
			GRAFANA_DOMAIN:      input.domain.infra.grafana
			ALERTMANAGER_DOMAIN: input.domain.infra.alertManager
			PROMETHEUS_DOMAIN:   input.domain.infra.prometheus
			NETWORK_TYPE:        input.networkType
			CHART_URL_INTERNAL:  origin.#Origin.prometheus.internal.url
			CHART_URL_GLOBAL:    origin.#Origin.prometheus.global.url
		}
		workdir: "/tmp"
		script: {
			directory: src.output
			filename:  "copy.sh"
		}
	}
	output: #Output & {
		image:   do.output
		success: do.success
	}
}
