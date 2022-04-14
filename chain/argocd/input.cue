package argocd

import (
	"dagger.io/dagger"
)

#Input: {
	"namespace": "argocd"
	version:     string | *"v2.3.3"
	url:         string | *"https://raw.githubusercontent.com/argoproj/argo-cd/\(version)/manifests/install.yaml"
	kubeconfig:  dagger.#Secret
	waitFor:     bool | *true
}
