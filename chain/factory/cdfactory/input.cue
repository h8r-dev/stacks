package cdfactory

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
	"universe.dagger.io/docker"
)

#Input: {
	provider:    string | *"argocd"
	kubeconfig:  dagger.#Secret
	repositorys: docker.#Image
	domain:      basefactory.#DefaultDomain
}
