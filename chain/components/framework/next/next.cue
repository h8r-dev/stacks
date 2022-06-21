package next

import (
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

// Copy Resource Code to specific path in image
#Instance: {
	input: #Input

	_file: core.#Source & {
		path: "template"
	}

	src: core.#Source & {
		path: "."
	}

	_sourceCode: docker.#Copy & {
		"input":  input.image
		contents: _file.output
		dest:     "/scaffold/\(input.name)"
	}

	do: bash.#Run & {
		"input": _sourceCode.output
		env: APP_NAME: input.name
		script: {
			directory: src.output
			filename:  "copy.sh"
		}
	}

	output: #Output & {
		image: do.output
	}
}
