package dapr

import (
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
)

#Input: {
	version:     string | *"1.7.3"
	helmName:    string
	image:       docker.#Image
	domain:      basefactory.#DefaultDomain
	networkType: string
}
