package nocalhost

import (
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
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
			VERSION:          input.version
			OUTPUT_PATH:      input.helmName
			NOCALHOST_DOMAIN: basefactory.#DefaultDomain.infra.nocalhost
		}
		workdir: "/tmp"
		script: {
			directory: src.output
			filename:  "copy.sh"
		}
		mounts: ingress: {
			dest:     "/ingress"
			contents: src.output
		}
	}
	output: #Output & {
		image:   do.output
		success: do.success
	}
}
