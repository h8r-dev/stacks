package sealedSecrets

import (
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
	"universe.dagger.io/docker"
)

#Input: {
	version:     string | *"2.1.8"
	helmName:    string
	image:       docker.#Image
	domain:      basefactory.#DefaultDomain
	networkType: string
}
