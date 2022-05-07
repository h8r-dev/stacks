package spring

import (
	"universe.dagger.io/docker"
)

#Input: {
	name:  string
	image: docker.#Image
}
