package next

import (
	"universe.dagger.io/docker"
	"dagger.io/dagger/core"
)

#Instance: {
	input: #Input

	_file: core.#Source & {
		path: "template"
	}

	do: docker.#Copy & {
		"input":  input.image
		contents: _file.output
		dest:     "/scaffold/\(input.name)"
	}

	output: #Output & {
		image: do.output
	}
}
