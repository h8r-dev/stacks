package prometheus

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
	"universe.dagger.io/docker"
)

#Input: {
	version: string | *"34.9.0"

	helmName:    string
	networkType: string
	kubeconfig:  dagger.#Secret
	image:       docker.#Image
	namespace:   string
	waitFor:     bool | *true
	domain:      basefactory.#DefaultDomain
}
