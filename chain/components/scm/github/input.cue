package github

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
)

#Input: {
	organization:        string
	personalAccessToken: dagger.#Secret
	image:               docker.#Image
	visibility:          string
	kubeconfig:          dagger.#Secret
}
