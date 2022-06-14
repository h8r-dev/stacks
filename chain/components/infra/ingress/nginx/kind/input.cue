package kind

import (
	"universe.dagger.io/docker"
)

#Input: {
	version: string | *"helm-chart-4.0.19"
	// for tgz output path
	helmName: string
	image:    docker.#Image
	url:      string | *"https://raw.githubusercontent.com/kubernetes/ingress-nginx/\(version)/deploy/static/provider/kind/deploy.yaml"
}
