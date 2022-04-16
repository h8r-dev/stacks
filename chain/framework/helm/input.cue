package helm

import (
	"universe.dagger.io/docker"
)

#Input: {
	name:  string
	image: docker.#Image
	// Helm values set
	// Format: '.image.repository = "rep" | .image.tag = "tag"'
	set: string | *""
}
