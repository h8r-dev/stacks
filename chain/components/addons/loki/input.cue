package loki

import (
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
	"universe.dagger.io/docker"
)

#Input: {
	version: string | *"2.6.2"
	// for tgz output path
	helmName:    string
	image:       docker.#Image
	domain:      basefactory.#DefaultDomain
	networkType: string
}
