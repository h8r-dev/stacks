package prometheus

import (
	"universe.dagger.io/bash"
	"dagger.io/dagger/core"
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
