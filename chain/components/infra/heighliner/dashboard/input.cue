package dashboard

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
	"universe.dagger.io/docker"
)

#Input: {
	version:             string | *"0.1.2"
	helmName:            string
	networkType:         string
	kubeconfig:          dagger.#Secret
	originalKubeconfig?: dagger.#Secret
	image:               docker.#Image
	namespace:           string
	waitFor:             bool | *true
	domain:              basefactory.#DefaultDomain
	withoutDashboard:    string
}
