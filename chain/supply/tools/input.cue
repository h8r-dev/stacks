package tools

import (
	"dagger.io/dagger"
)

#Input: {
	#toolList: {
		name:    string
		version: string
	}

	// tools name
	"tools": [...#toolList]

	// tools version
	kubeconfig: dagger.#Secret
	waitFor:    bool | *true
}
