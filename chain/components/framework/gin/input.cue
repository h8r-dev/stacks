package gin

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
)

#Input: {
	name:       string
	image:      docker.#Image
	kubeconfig: dagger.#Secret
}
