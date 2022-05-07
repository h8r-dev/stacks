package scmfactory

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
)

#Input: {
	provider:            string | *"github" | "gitlab"
	personalAccessToken: dagger.#Secret
	organization:        string
	repositorys:         docker.#Image
	// Repo visibility
	visibility: string | "public" | *"private"
	kubeconfig: dagger.#Secret
}
