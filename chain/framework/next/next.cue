package next

import (
	"universe.dagger.io/docker"
	"universe.dagger.io/bash"
	"dagger.io/dagger/core"
)

#Instance: {
	input: #Input

	_file: core.#Source & {
		path: "template"
	}

	_sourceCode: docker.#Copy & {
		"input":  input.image
		contents: _file.output
		dest:     "/scaffold/\(input.name)"
	}

	do: bash.#Run & {
		"input": _sourceCode.output
		env: APP_NAME: input.name
		script: contents: """
				sed -i "s/appname/$APP_NAME/" /scaffold/$APP_NAME/package.json
			"""
	}

	output: #Output & {
		image: do.output
	}
}
