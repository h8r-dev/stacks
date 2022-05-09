package cloud

import (
	"dagger.io/dagger"
)

#Input: {
	namespace:  string | *"ingress-nginx"
	action:     string | *"installOrUpgrade"
	repository: string | *"https://kubernetes.github.io/ingress-nginx"
	kubeconfig: dagger.#Secret
	values:     string | *null
	wait:       bool | *true
	version:    string | *"4.0.19"
	waitFor:    bool | *true
}
