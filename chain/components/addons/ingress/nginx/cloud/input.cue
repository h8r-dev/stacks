package cloud

import (
	"universe.dagger.io/docker"
)

#Input: {
	version: string | *"4.0.19"
	// for tgz output path
	helmName:   string
	image:      docker.#Image
	repository: string | *"https://kubernetes.github.io/ingress-nginx"
}
