package prometheus

import (
	"universe.dagger.io/docker"
)

#Input: {
	version: string | *"34.9.0"
	// for tgz output path
	helmName: string
	image:    docker.#Image
}
