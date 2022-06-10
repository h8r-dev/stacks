package base

import (
	"universe.dagger.io/docker"
)

#Image: {
	docker.#Pull & {
		source: "heighlinerdev/stack-base:debian"
	}
}
