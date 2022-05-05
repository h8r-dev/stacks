package prometheus

import (
	"universe.dagger.io/bash"
	"dagger.io/dagger/core"
	"github.com/h8r-dev/chain/supply/base"
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
			GRAFANA_DOMAIN:      base.#DefaultDomain.infra.grafana
			ALERTMANAGER_DOMAIN: base.#DefaultDomain.infra.alertManager
			PROMETHEUS_DOMAIN:   base.#DefaultDomain.infra.prometheus
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
