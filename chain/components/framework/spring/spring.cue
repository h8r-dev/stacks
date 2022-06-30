package spring

import (
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
)

#Instance: {
	input: #Input
	_file: core.#Source & {
		path: "template"
	}
	_manifests: core.#Source & {
		path: "dashboards"
	}
	do: docker.#Copy & {
		"input":  input.image
		contents: _file.output
		dest:     "/scaffold/\(input.name)"
	}
	createDashboardManifest: docker.#Copy & {
		input:    do.output
		contents: _manifests.output
		dest:     "/dashboards"
	}
	output: #Output & {
		image: createDashboardManifest.output
	}
}
