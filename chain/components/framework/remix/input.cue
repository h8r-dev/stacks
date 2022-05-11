package remix

import (
	"universe.dagger.io/docker"
)

#Input: {
	name:       string
	image:      docker.#Image
	typescript: bool | *true
	template:   string | *"h8r-dev/remix-stack-template"
	registry:   string | *"https://github.com"
}
