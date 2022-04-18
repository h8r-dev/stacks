package helm

import (
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"dagger.io/dagger/core"
)

#Instance: {
	input:  #Input
	_build: bash.#Run & {
		env: {
			NAME:     input.chartName
			HELM_SET: input.set
		}
		"input": input.image
		workdir: "/tmp"
		script: contents: """
				helm create $NAME
				cd $NAME
				if [ !$HELM_SET ]; then
					set="yq -i $HELM_SET values.yaml"
					eval $set
				fi
			"""
	}
	_outputHelm: core.#Subdir & {
		"input": _build.output.rootfs
		path:    "/tmp/\(input.chartName)"
	}
	do: docker.#Copy & {
		"input":  input.image
		contents: _outputHelm.output
		dest:     "/scaffold/\(input.name)/\(input.chartName)"
	}
	output: #Output & {
		image: do.output
	}
}
