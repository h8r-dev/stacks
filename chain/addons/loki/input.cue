package loki

import (
	"universe.dagger.io/docker"
)

#Input: {
	version: string | *"2.6.2"
	// for tgz output path
	helmName: string
	image:    docker.#Image
}
