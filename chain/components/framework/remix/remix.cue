package remix

import (
	"universe.dagger.io/bash"
	"dagger.io/dagger/core"
)

// Create a new remix app
#Instance: {
	input: #Input

	scriptFiles: core.#Source & {
		path: "."
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

	output: #Output & {
		image: do.output
	}
}
