package loki

import (
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
)

#Input: {
	version: string | *"2.6.2"
	// for tgz output path
	helmName: string
	image:    docker.#Image
	domain:   basefactory.#DefaultDomain
}
