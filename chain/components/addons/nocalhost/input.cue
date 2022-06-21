package nocalhost

import (
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
	"universe.dagger.io/docker"
)

#Input: {
	version: string | *"0.6.19-beta.2"
	// for tgz output path
	helmName:    string
	image:       docker.#Image
	domain:      basefactory.#DefaultDomain
	networkType: string
}
