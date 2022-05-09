package next

import (
	"universe.dagger.io/docker"
)

#Input: {
	name:       string
	image:      docker.#Image
	typescript: bool | *true
}
