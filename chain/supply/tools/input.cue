package tools

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
)

#Input: {
	#tool: {
		name:    string
		version: string
		domain:  string
	}

	// tools name
	tools: [...#tool]
	image: docker.#Image
	// tools version
	kubeconfig: dagger.#Secret
	waitFor:    bool | *true
}
