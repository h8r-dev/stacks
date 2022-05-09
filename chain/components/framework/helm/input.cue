package helm

import (
	"universe.dagger.io/docker"
)

#Input: {
	name:      string
	chartName: string
	image:     docker.#Image
	// Helm values set
	// Format: '.image.repository = "rep" | .image.tag = "tag"'
	set?: string | *""
	// Helm starter scaffold
	starter?: string | *""
}
