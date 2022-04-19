package cd

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
)

#Input: {
	provider:    string | *"argocd"
	kubeconfig:  dagger.#Secret
	repositorys: docker.#Image
}
