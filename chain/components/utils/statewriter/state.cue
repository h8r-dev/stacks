package statewriter

import (
	"universe.dagger.io/docker"
)

// Please write output info into /hln/output.yaml
#Output: {
	input: _

	run: docker.#Run & {
		"input": input.image
		export: files: "/hln/output.yaml": string
	}

	contents: run.export.files."/hln/output.yaml"
}
