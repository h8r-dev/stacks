package cdfactory

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
)

#Input: {
	provider:    string | *"argocd"
	kubeconfig:  dagger.#Secret
	repositorys: docker.#Image
	domain:      basefactory.#DefaultDomain
}
