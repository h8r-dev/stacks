package github

import (
	"strings"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
)

#Instance: {
	input: #Input
	src:   core.#Source & {
		path: "."
	}
	do: bash.#Run & {
		env: {
			NAME:     input.chartName
			USERNAME: strings.ToLower(input.username)
			PASSWORD: input.password
			DIR_NAME: input.name
			TAG:      input.tag
			APP_NAME: input.appName
		}
		"input": input.image
		// work dir is deploy path
		workdir: "/scaffold/\(input.chartName)"
		script: {
			directory: src.output
			filename:  "github-registry.sh"
		}
		if input.kubeconfig != _|_ {
			mounts: kubeconfig: {
				dest:     "/kubeconfig"
				contents: input.kubeconfig
			}
		}
	}
	output: #Output & {
		image: do.output
	}
}
