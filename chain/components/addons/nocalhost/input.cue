package nocalhost

import (
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
)

#Input: {
	version: string | *"0.6.16"
	// for tgz output path
	helmName: string
	image:    docker.#Image
	domain:   basefactory.#DefaultDomain
}
