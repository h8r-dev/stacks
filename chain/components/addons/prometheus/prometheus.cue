package prometheus

import (
	"universe.dagger.io/bash"
	"dagger.io/dagger/core"
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
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
			GRAFANA_DOMAIN:      basefactory.#DefaultDomain.infra.grafana
			ALERTMANAGER_DOMAIN: basefactory.#DefaultDomain.infra.alertManager
			PROMETHEUS_DOMAIN:   basefactory.#DefaultDomain.infra.prometheus
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
