package kubeconfig

import (
	"dagger.io/dagger"
)

#Output: {
	kubeconfig: dagger.#Secret
	apiServer:  string
}
