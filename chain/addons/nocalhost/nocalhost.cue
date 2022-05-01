package nocalhost

import (
	"universe.dagger.io/bash"
	"dagger.io/dagger/core"
)

// TODO generate nocalhost ingress yaml
#Instance: {
	input: #Input
	src:   core.#Source & {
		path: "."
	}
	do: bash.#Run & {
		"input": input.image
		env: {
			VERSION:     input.version
			OUTPUT_PATH: input.helmName
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
