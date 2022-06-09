package statewriter

import (
	"universe.dagger.io/docker"
)

// Please write output info into /hln/output.yaml
#StoreInFile: {
	input: _

	run: docker.#Run & {
		"input": input.image
		export: files: "/hln/output.yaml": string
	}

	contents: run.export.files."/hln/output.yaml"
}

#StoreInK8S: {
	input: _

	run: docker.#Run & {
		"input": input.image
		export: files: "/hln/output.yaml": string
	}

	contents: run.export.files."/hln/output.yaml"
}
