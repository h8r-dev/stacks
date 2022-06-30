package sealedSecrets

import (
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
)

#Input: {
	version:     string | *"2.1.8"
	helmName:    string
	image:       docker.#Image
	domain:      basefactory.#DefaultDomain
	networkType: string
}
