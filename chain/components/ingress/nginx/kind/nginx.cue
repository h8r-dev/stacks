package kind

import (
	"github.com/h8r-dev/stacks/chain/internal/deploy/kubectl"
)

#Instance: {
	input:   #Input
	install: kubectl.#Apply & {
		url:        input.url
		namespace:  input.namespace
		kubeconfig: input.kubeconfig
		waitFor:    input.waitFor
	}
	output: #Output & {
		image:   install.output
		success: install.success
	}
}
