package github

import (
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
)

#Create: {
	input: docker.#Image

	// Copy dest path
	path: string

	actionFile: core.#Source & {
		path: "action"
	}

	run: docker.#Copy & {
		"input":  input
		contents: actionFile.output
		dest:     "/root/" + path + "/"
	}

	output: run.output
}
