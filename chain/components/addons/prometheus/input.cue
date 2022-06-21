package prometheus

import (
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
	"universe.dagger.io/docker"
)

#Input: {
	version: string | *"34.9.0"
	// for tgz output path
	helmName:    string
	image:       docker.#Image
	domain:      basefactory.#DefaultDomain
	networkType: string
}
