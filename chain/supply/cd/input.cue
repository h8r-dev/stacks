package cd

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/chain/supply/base"
)

#Input: {
	provider:    string | *"argocd"
	kubeconfig:  dagger.#Secret
	repositorys: docker.#Image
	domain:      string | *base.#DefaultDomain.infra.argocd
}
