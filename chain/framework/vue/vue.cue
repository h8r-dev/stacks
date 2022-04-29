package vue

import (
	"universe.dagger.io/docker"
	"universe.dagger.io/bash"
	"dagger.io/dagger/core"
)

#Instance: {
	input: #Input

	_build: bash.#Run & {
		"input": input.image
		workdir: "/scaffold"
		env: {
			APP_NAME: input.name
		}
		script: contents: #"""
			npm config set registry http://mirrors.cloud.tencent.com/npm/
			echo "Y" | vue create $APP_NAME -d --no-git
			"""#
	}
	_file: core.#Source & {
		path: "template"
	}
	do: docker.#Copy & {
		"input":  _build.output
		contents: _file.output
		dest:     "/scaffold/\(input.name)"
	}

	output: #Output & {
		image: do.output
	}
}
