package state

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"github.com/h8r-dev/stacks/chain/internal/deploy/kubectl"
)

#Store: {
	namespace:  string
	kubeconfig: dagger.#Secret
	waitFor:    bool | *"true"

	src: core.#Source & {
		path: "."
	}

	manifest: core.#ReadFile & {
		input: src.output
		path:  "./default-infra-output.yaml"
	}

	run: kubectl.#Manifest & {
		"waitFor":    waitFor
		"manifest":   manifest.contents
		"namespace":  namespace
		"kubeconfig": kubeconfig
	}
}
