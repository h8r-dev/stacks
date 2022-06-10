package prometheus

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
)

#Input: {
	version:     string | *"34.9.0"
	helmName:    string // for tgz output path
	image:       docker.#Image
	domain:      basefactory.#DefaultDomain
	networkType: string
	kubeconfig:  dagger.#Secret
}
