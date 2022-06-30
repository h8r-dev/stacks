package argocd

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
)

#Input: {
	namespace:   "argocd"
	version:     string | *"v2.3.3"
	url:         string | *"https://raw.githubusercontent.com/argoproj/argo-cd/\(version)/manifests/install.yaml"
	kubeconfig:  dagger.#Secret
	image:       docker.#Image
	waitFor:     bool | *true
	domain:      basefactory.#DefaultDomain
	networkType: string
	// Helm set values, such as "key1=value1,key2=value2"
	set: string | *null
}
