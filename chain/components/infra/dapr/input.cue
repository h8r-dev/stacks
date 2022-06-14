package dapr

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
)

#Input: {
	version:     string | *"1.7.3"
	helmName:    string
	image:       docker.#Image
	domain:      basefactory.#DefaultDomain
	networkType: string
	kubeconfig:  dagger.#Secret
}
