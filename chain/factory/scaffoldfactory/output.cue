package scaffoldfactory

import (
	"universe.dagger.io/docker"
)

#Output: {
	image:   docker.#Image
	success: bool | *true
}
