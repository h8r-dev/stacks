package dapr

import (
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
	"universe.dagger.io/docker"
)

#Input: {
	version:     string | *"1.7.3"
	helmName:    string
	image:       docker.#Image
	domain:      basefactory.#DefaultDomain
	networkType: string
}
