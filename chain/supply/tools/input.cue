package tools

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
)

#Input: {
	#toolList: {
		name:    string
		version: string
		domain:  string
	}

	// tools name
	tools: [...#toolList]
	image: docker.#Image
	// tools version
	kubeconfig: dagger.#Secret
	waitFor:    bool | *true
}
