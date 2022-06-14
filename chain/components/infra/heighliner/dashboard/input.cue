package dashboard

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
)

#Input: {
	version:     string | *"0.1.0"
	helmName:    string
	networkType: string
	kubeconfig:  dagger.#Secret
	image:       docker.#Image
	namespace:   string
	waitFor:     bool | *true
	domain:      basefactory.#DefaultDomain
}
