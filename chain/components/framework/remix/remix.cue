package remix

import (
	"universe.dagger.io/bash"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
)

// Create a new remix app
#Instance: {
	input: #Input

	scriptFiles: core.#Source & {
		path: "."
	}

	_manifests: core.#Source & {
		path: "dashboards"
	}

	do: bash.#Run & {
		"input": input.image
		env: {
			APP_NAME: input.name
			if input.typescript == true {
				ENABLE_TYPESCRIPT: "enable"
			}
			APP_TEMPLATE: input.template
			REGISTRY:     input.registry
		}
		script: {
			directory: scriptFiles.output
			filename:  "init.sh"
		}
	}

	createDashboardManifest: docker.#Copy & {
		input:    do.output
		contents: _manifests.output
		dest:     "/dashboards"
	}

	output: #Output & {
		image: createDashboardManifest.output
	}
}
