package nocalhost

import (
	"universe.dagger.io/docker"
)

#Input: {
	version: string | *"0.6.16"
	// for tgz output path
	helmName: string
	image:    docker.#Image
}
